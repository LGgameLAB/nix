#!/bin/bash
OUTPUT_FILE="/var/lib/node_exporter/textfile_collector/logged_in_users.prom"
> "$OUTPUT_FILE"
loginctl list-sessions --no-legend | while read -r session_id uid user seat leader class tty idle since; do
  if [[ $class == "user" ]] && [[ $seat == "seat0" ]] && [[ $idle == "no" ]]; then
    state=$(loginctl show-session "$session_id" -p State --value)
    if [[ $state == "active" ]]; then
      locked_status="unlocked"
    else
      locked_status="locked"
    fi
  echo "node_logged_in_user{name=\"$user\", state=\"$locked_status\"} 1" > $OUTPUT_FILE
  fi
done
