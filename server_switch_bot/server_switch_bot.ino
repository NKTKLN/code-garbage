#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>

/* WiFi credentials */
const char* ssid = "WIFI_NAME";
const char* password = "WIFI_PASSWORD";

/* Telegram bot token */
#define BOT_TOKEN "BOT_TOKEN"

/* Telegram chat and topic */
#define CHAT_ID   "2075131720"
#define TOPIC_ID  2761   // message_thread_id

WiFiClientSecure client;
UniversalTelegramBot bot(BOT_TOKEN, client);

/* ESP-01 GPIO */
#define PWR_PIN 2   // GPIO2

/* Relay logic (active LOW) */
const int RELAY_ON  = LOW;
const int RELAY_OFF = HIGH;

/* Simulate power button press */
void pressPower(int durationMs) {
  digitalWrite(PWR_PIN, RELAY_ON);
  delay(durationMs);
  digitalWrite(PWR_PIN, RELAY_OFF);
}

/* Send message to specific topic */
void sendMessage(const String& text) {
  bot.sendMessage(CHAT_ID, text, "", TOPIC_ID);
}

void setup() {
  /* IMPORTANT: set output level before pinMode */
  digitalWrite(PWR_PIN, RELAY_OFF);
  pinMode(PWR_PIN, OUTPUT);

  WiFi.begin(ssid, password);
  client.setInsecure();

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }

  sendMessage("🟢 Power switch online.");
}

void loop() {
  int messageCount = bot.getUpdates(bot.last_message_received + 1);

  while (messageCount) {
    for (int i = 0; i < messageCount; i++) {

      /* Security: allow only one chat */
      if (bot.messages[i].chat_id != CHAT_ID) continue;

      String cmd = bot.messages[i].text;

      if (cmd == "pressbutton") {
        pressPower(700);
        sendMessage("⏺️ Power button pressed (short)");
      }

      else if (cmd == "forcestop") {
        pressPower(6000);
        sendMessage("🔴 Forced power off");
      }

      else if (cmd == "reboot") {
        pressPower(6000);
        delay(3000);
        pressPower(700);
        sendMessage("🔄 Reboot completed (power cycle)");
      }
    }

    messageCount = bot.getUpdates(bot.last_message_received + 1);
  }

  delay(800);
}
