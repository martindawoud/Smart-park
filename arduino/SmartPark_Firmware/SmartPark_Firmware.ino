/*
 * SmartPark Arduino Firmware
 * ===========================
 * Hardware:
 *   - Arduino Uno / Mega
 *   - HC-05 Bluetooth Module (TX→D11, RX→D10  or  TX→D1, RX→D0)
 *   - 6x IR Obstacle Sensors (D2–D7)
 *   - Servo Motor (D9) — barrier gate
 *   - Optional: LCD 16x2 (I2C at 0x27)
 *
 * Wiring HC-05:
 *   HC-05 VCC → 5V
 *   HC-05 GND → GND
 *   HC-05 TX  → Arduino D10 (SoftwareSerial RX)
 *   HC-05 RX  → Arduino D11 through voltage divider → 3.3V
 *
 * JSON format sent every 1 second:
 * {"total":6,"occupied":3,"available":3,"slots":[1,0,1,0,1,0],
 *  "sensor_health":["ok","ok","ok","ok","ok","ok"],
 *  "critical_fault":false,"timestamp":12345}
 *
 * Commands received from app:
 *   PING        → replies "PONG\n"
 *   GATE_TOGGLE → toggles servo gate
 */

#include <SoftwareSerial.h>
#include <Servo.h>
#include <ArduinoJson.h>   // Install: Library Manager → ArduinoJson by Benoit Blanchon

// ── Pin Definitions ────────────────────────────────────────
#define BT_RX_PIN    10    // HC-05 TX → Arduino pin 10
#define BT_TX_PIN    11    // HC-05 RX → Arduino pin 11
#define SERVO_PIN     9
#define NUM_SLOTS     6

const int IR_PINS[NUM_SLOTS] = {2, 3, 4, 5, 6, 7};
// IR sensor: LOW = object detected (occupied), HIGH = free
// Adjust based on your sensor logic (some are inverted)
#define IR_OCCUPIED_LEVEL LOW

// ── Watchdog config ───────────────────────────────────────
#define WATCHDOG_TIMEOUT_MS 5000   // ms without valid reading = fault
#define SEND_INTERVAL_MS    1000   // JSON send interval

// ── Globals ───────────────────────────────────────────────
SoftwareSerial btSerial(BT_RX_PIN, BT_TX_PIN);
Servo gateServo;

bool slotOccupied[NUM_SLOTS]   = {false};
bool sensorFault[NUM_SLOTS]    = {false};
unsigned long lastRead[NUM_SLOTS] = {0};
unsigned long lastSend         = 0;
bool gateOpen                  = true;

// ── Setup ─────────────────────────────────────────────────
void setup() {
  Serial.begin(9600);
  btSerial.begin(9600);   // HC-05 default baud

  // IR sensor pins
  for (int i = 0; i < NUM_SLOTS; i++) {
    pinMode(IR_PINS[i], INPUT);
    lastRead[i] = millis();
  }

  // Servo
  gateServo.attach(SERVO_PIN);
  gateServo.write(0);   // Gate closed = 0°, Open = 90°
  openGate();

  Serial.println("SmartPark Arduino Ready");
}

// ── Loop ──────────────────────────────────────────────────
void loop() {
  // 1. Read all IR sensors
  for (int i = 0; i < NUM_SLOTS; i++) {
    int reading = digitalRead(IR_PINS[i]);
    bool occupied = (reading == IR_OCCUPIED_LEVEL);

    // Watchdog: if reading changed, reset timer
    if (occupied != slotOccupied[i]) {
      lastRead[i] = millis();
    }

    slotOccupied[i] = occupied;

    // Check watchdog timeout
    if (millis() - lastRead[i] > WATCHDOG_TIMEOUT_MS) {
      sensorFault[i] = true;
    } else {
      sensorFault[i] = false;
    }
  }

  // 2. Update gate based on availability
  int occupied = 0;
  for (int i = 0; i < NUM_SLOTS; i++) {
    if (slotOccupied[i] || sensorFault[i]) occupied++;
  }
  if (occupied >= NUM_SLOTS) {
    closeGate();
  } else {
    openGate();
  }

  // 3. Send JSON packet every SEND_INTERVAL_MS
  if (millis() - lastSend >= SEND_INTERVAL_MS) {
    lastSend = millis();
    sendJsonPacket(occupied);
  }

  // 4. Read commands from app
  handleIncomingCommands();

  delay(50);
}

// ── Send JSON ─────────────────────────────────────────────
void sendJsonPacket(int occupied) {
  StaticJsonDocument<512> doc;

  doc["total"]    = NUM_SLOTS;
  doc["occupied"] = occupied;
  doc["available"]= NUM_SLOTS - occupied;

  JsonArray slots = doc.createNestedArray("slots");
  JsonArray health = doc.createNestedArray("sensor_health");

  bool anyCritical = false;
  for (int i = 0; i < NUM_SLOTS; i++) {
    slots.add(slotOccupied[i] ? 1 : 0);
    if (sensorFault[i]) {
      health.add("fault");
      anyCritical = true;
    } else {
      health.add("ok");
    }
  }

  doc["critical_fault"] = anyCritical;
  doc["timestamp"] = millis() / 1000;

  String output;
  serializeJson(doc, output);
  output += "\n";   // Newline delimiter — important for app parsing

  btSerial.print(output);
  Serial.print("Sent: ");
  Serial.print(output);
}

// ── Command Handler ───────────────────────────────────────
void handleIncomingCommands() {
  if (!btSerial.available()) return;

  String cmd = btSerial.readStringUntil('\n');
  cmd.trim();
  Serial.print("CMD: ");
  Serial.println(cmd);

  if (cmd == "PING") {
    btSerial.println("PONG");
  } else if (cmd == "GATE_TOGGLE") {
    if (gateOpen) {
      closeGate();
    } else {
      openGate();
    }
    btSerial.println("GATE_OK");
  } else if (cmd == "STATUS") {
    btSerial.println("READY");
  }
}

// ── Servo Gate ────────────────────────────────────────────
void openGate() {
  if (!gateOpen) {
    gateServo.write(90);   // 90° = raised/open
    gateOpen = true;
    Serial.println("Gate: OPEN");
  }
}

void closeGate() {
  if (gateOpen) {
    gateServo.write(0);    // 0° = lowered/closed
    gateOpen = false;
    Serial.println("Gate: CLOSED");
  }
}
