#!/bin/bash
OUTPUT_FILE="/var/lib/node_exporter/textfile_collector/logged_in_users.prom"
> "$OUTPUT_FILE"

loginctl list-sessions --no-legend | while read -r session_id uid user seat leader class tty idle since; do
  if [[ $class == "user" ]] && [[ $seat == "seat0" ]] && [[ $idle == "no" ]]; then
    # we only want to list users who are:
    # - online: logged in but not in the foreground
    # - active: logged in and in the foreground
    # TODO: list logged in users but dont place a penguin if no sessions are active
    session_status=$(loginctl show-session "$session_id" -p State --value)
    if ! [[ $session_status == "online" || $session_status == "active" ]]; then
      continue
    fi

    # If the locking program supports systemd-logind, LockedHint can checked instead.
    # To support lockers that do not support logind, locked_status is only set to
    # locked if LockedHint specifically says so.
    session_lockedhint=$(loginctl show-session "$session_id" -p LockedHint --value)
    if [[ $session_lockedhint == "yes" ]]; then
      locked_status="locked"
    else
      locked_status="unlocked"
    fi

    echo "node_logged_in_user{name=\"$user\", state=\"$locked_status\"} 1" > $OUTPUT_FILE
  fi
done
