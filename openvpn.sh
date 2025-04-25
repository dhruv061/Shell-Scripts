#!/bin/bash

# 🎯 Configuration Variables (edit these)
FILEPATH=".OVPN FILE PATH" # e.g., /path/demo.ovpn
USERNAME="USERNAME"
PASSWORD="PASSWORD"
CONFIG_NAME="YOURNAME"  # e.g., myvpn-us

# ⚙️ No Need to Change These
AUTH_FILE="/tmp/openvpn-auth-$CONFIG_NAME.txt"
TEMP_CONFIG="/tmp/${CONFIG_NAME}_auto.ovpn"

# 💬 Stylish Echo Helpers
print_line() {
  echo "────────────────────────────────────────────"
}

fancy_echo() {
  echo -e "\n🌟 $1"
  print_line
}

error_echo() {
  echo -e "\n❌ $1"
  print_line
}

success_echo() {
  echo -e "\n✅ $1"
  print_line
}

# 🚀 Main Menu
while true; do
  clear
  echo -e "\n📡 \e[1mOpenVPN CLI Manager 🌐\e[0m"
  print_line
  echo -e "1 - Add New Configuration"
  echo -e "2 - Start OpenVPN"
  echo -e "3 - Disconnect OpenVPN"
  echo -e "4 - Remove Configuration"
  echo -e "5 - Show Current Sessions"
  echo -e "6 - Show Existing Configurations \n"
  echo -e "   Press Ctrl+C to Exit"
  print_line
  read -p "👉 Choose an option (1-6): " option

  case $option in
    1)
      fancy_echo "Importing Configuration with Credentials..."

      echo -e "$USERNAME\n$PASSWORD" > "$AUTH_FILE"
      chmod 600 "$AUTH_FILE"

      cp "$FILEPATH" "$TEMP_CONFIG"
      if grep -q "^auth-user-pass" "$TEMP_CONFIG"; then
        sed -i "s|^auth-user-pass.*|auth-user-pass $AUTH_FILE|" "$TEMP_CONFIG"
      else
        echo "auth-user-pass $AUTH_FILE" >> "$TEMP_CONFIG"
      fi

      openvpn3 config-import --config "$TEMP_CONFIG" --name "$CONFIG_NAME" --persistent
      openvpn3 configs-list
      openvpn3 config-show --config "$CONFIG_NAME"
      success_echo "Configuration imported successfully as ➡️  \e[1m$CONFIG_NAME\e[0m"

      rm -f "$TEMP_CONFIG"
      ;;

    2)
      if ! openvpn3 configs-list | grep -q "$CONFIG_NAME"; then
        error_echo "No configuration found for ➡️  \e[1m$CONFIG_NAME\e[0m\n💡 Please add a configuration first (option 1)."
      else
        fancy_echo "Starting OpenVPN..."
        openvpn3 session-start --config "$CONFIG_NAME"
        openvpn3 sessions-list
        success_echo "VPN is now connected with ➡️  \e[1m$CONFIG_NAME\e[0m"
      fi
      ;;

    3)
      fancy_echo "Checking VPN connection status..."
      if openvpn3 sessions-list | grep -q "$CONFIG_NAME"; then
        fancy_echo "Disconnecting OpenVPN..."
        openvpn3 session-manage --disconnect --config "$CONFIG_NAME"
        success_echo "Disconnected ➡️  \e[1m$CONFIG_NAME\e[0m\n🥺 Tu si najao!"
      else
        error_echo "No active VPN session found for ➡️  \e[1m$CONFIG_NAME\e[0m"
      fi
      ;;

    4)
      fancy_echo "Checking for existing configuration..."
      if openvpn3 configs-list | grep -q "$CONFIG_NAME"; then
        fancy_echo "Removing Configuration..."
        openvpn3 config-remove --config "$CONFIG_NAME"
        success_echo "Configuration ➡️  \e[1m$CONFIG_NAME\e[0m removed 🗑️"
      else
        error_echo "No configuration found to remove for ➡️  \e[1m$CONFIG_NAME\e[0m"
      fi
      ;;

    5)
      fancy_echo "🌀 Active VPN Sessions:"
      openvpn3 sessions-list
      print_line
      ;;

    6)
      fancy_echo "📄 Existing OpenVPN Configurations:"
      openvpn3 configs-list
      print_line
      ;;

    *)
      error_echo "Please enter a valid option between 1 and 6 🔢"
      ;;
  esac
  
  echo ""
  read -p "Press Enter to continue..."
done