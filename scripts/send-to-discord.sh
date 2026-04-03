#!/bin/sh
# Send a file to a Discord channel via webhook or bot API
# Usage: send-to-discord.sh <file-path> <channel-id> [message]
#
# Requires DISCORD_BOT_TOKEN env var

FILE="$1"
CHANNEL_ID="$2"
MESSAGE="${3:-📎 File attached}"

if [ -z "$FILE" ] || [ -z "$CHANNEL_ID" ]; then
  echo "Usage: send-to-discord.sh <file-path> <channel-id> [message]"
  exit 1
fi

if [ -z "$DISCORD_BOT_TOKEN" ]; then
  echo "❌ DISCORD_BOT_TOKEN not set"
  exit 1
fi

curl -s -X POST \
  "https://discord.com/api/v10/channels/${CHANNEL_ID}/messages" \
  -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
  -F "content=${MESSAGE}" \
  -F "files[0]=@${FILE}" \
  | jq '.id // .message // "sent"'

echo "✅ File sent to channel ${CHANNEL_ID}"
