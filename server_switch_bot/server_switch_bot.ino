#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <UniversalTelegramBot.h>
#include <time.h>

/* ================= CONFIG ================= */

#define WIFI_SSID     "WIFI_SSID"
#define WIFI_PASSWORD "WIFI_PASSWORD"

#define BOT_TOKEN "BOT_TOKEN"
#define CHAT_ID   "CHAT_ID"

#define PWR_PIN 0        // ESP-01 GPIO0 (active LOW)
#define BOT_MTBS 1000

#define WIFI_RECONNECT_INTERVAL 10000UL  // 10 sec

/* ========================================= */

const int RELAY_ON  = LOW;
const int RELAY_OFF = HIGH;

unsigned long lastWifiCheck = 0;
bool wifiWasConnected = false;

WiFiClientSecure client;
UniversalTelegramBot bot(BOT_TOKEN, client);
unsigned long bot_lasttime;

/* ================= Wi-Fi =================*/

void connectWiFi()
{
  if (WiFi.status() == WL_CONNECTED)
    return;

  Serial.println("[WIFI] Reconnecting...");
  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 15000)
  {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.println();
    Serial.print("[WIFI] Reconnected, IP: ");
    Serial.println(WiFi.localIP());

    // Telegram HTTPS requires correct time
    configTime(0, 0, "pool.ntp.org");
    time_t now = time(nullptr);
    while (now < 24 * 3600)
    {
      delay(100);
      now = time(nullptr);
    }

    sendMessage("🟢 WiFi reconnected");
  }
  else
  {
    Serial.println();
    Serial.println("[WIFI] Reconnect failed");
  }
}

/* ================= POWER ================= */

void pressPower(uint32_t durationMs)
{
  Serial.print("[ACTION] Power press ");
  Serial.print(durationMs);
  Serial.println(" ms");

  digitalWrite(PWR_PIN, RELAY_ON);
  delay(durationMs);
  digitalWrite(PWR_PIN, RELAY_OFF);

  Serial.println("[ACTION] Power released");
}

/* ================= TELEGRAM ================= */

void sendMessage(const String &text)
{
  Serial.print("[TELEGRAM] Send: ");
  Serial.println(text);

  if (!bot.sendMessage(CHAT_ID, text, ""))
    Serial.println("[ERROR] sendMessage failed");
}

void sendCommandsMenu()
{
  String menu =
    "⚙️ *Power control commands*\n\n"
    "⏺ Short power press: /pressbutton\n\n"
    "🔄 Reboot server: /reboot\n\n"
    "🔴 Force power OFF: /forcestop\n\n"
    "ℹ️ Show this menu: /commands";

  if (!bot.sendMessage(CHAT_ID, menu, "Markdown"))
    Serial.println("[ERROR] sendCommandsMenu failed");
}

/* ================= HANDLERS ================= */

void handleCommand(const String &cmd)
{
  Serial.print("[CMD] ");
  Serial.println(cmd);

  if (cmd == "/start" || cmd == "/commands")
  {
    sendCommandsMenu();
  }
  else if (cmd == "/pressbutton")
  {
    pressPower(700);
    sendMessage("⏺ Power button pressed");
  }
  else if (cmd == "/forcestop")
  {
    pressPower(6000);
    sendMessage("🔴 Forced power off");
  }
  else if (cmd == "/reboot")
  {
    Serial.println("[ACTION] Reboot sequence");
    pressPower(6000);
    delay(3000);
    pressPower(700);
    sendMessage("🔄 Reboot completed");
  }
  else
  {
    Serial.println("[WARN] Unknown command");
  }
}

/* ================= UPDATE LOOP ================= */

void handleNewMessages(int count)
{
  Serial.print("[TELEGRAM] New messages: ");
  Serial.println(count);

  for (int i = 0; i < count; i++)
  {
    String chatId = bot.messages[i].chat_id;
    String text   = bot.messages[i].text;

    if (chatId != CHAT_ID)
    {
      Serial.println("[WARN] Unauthorized chat ignored");
      continue;
    }

    handleCommand(text);
  }
}

/* ================= SETUP ================= */

void setup()
{
  Serial.begin(115200);
  Serial.println();
  Serial.println("[BOOT] ESP-01 power bot");

  pinMode(PWR_PIN, OUTPUT);
  digitalWrite(PWR_PIN, RELAY_OFF);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  client.setInsecure();

  Serial.print("[WIFI] Connecting");
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(500);
  }

  Serial.println();
  Serial.print("[WIFI] IP: ");
  Serial.println(WiFi.localIP());

  // Telegram HTTPS requires correct time
  configTime(0, 0, "pool.ntp.org");
  time_t now = time(nullptr);
  while (now < 24 * 3600)
  {
    delay(100);
    now = time(nullptr);
  }
  
  sendMessage("🟢 Power switch online");
}

/* ================= LOOP ================= */

void loop()
{
  // ===== WiFi watchdog =====
  if (millis() - lastWifiCheck > WIFI_RECONNECT_INTERVAL)
  {
    lastWifiCheck = millis();

    if (WiFi.status() != WL_CONNECTED)
    {
      connectWiFi();
      wifiWasConnected = false;
      return;
    }
    else if (!wifiWasConnected)
    {
      wifiWasConnected = true;
      Serial.println("[WIFI] Connection stable");
    }
  }

  // ===== Telegram =====
  if (WiFi.status() == WL_CONNECTED &&
      millis() - bot_lasttime > BOT_MTBS)
  {
    int n = bot.getUpdates(bot.last_message_received + 1);
    Serial.println(n);
    while (n)
    {
      handleNewMessages(n);
      n = bot.getUpdates(bot.last_message_received + 1);
      Serial.println(n);
    }
    bot_lasttime = millis();
  }
}
