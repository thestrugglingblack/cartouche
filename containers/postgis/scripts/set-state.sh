#!/bin/bash

###
# Really simple state management.
###

STATE="$(cat $SCRIPT_PATH/DB_STATE)"
NEW_STATE=$1

VALID_STATES="INITIALIZE RESTORE READY SYNC"

# Each line represents a list of states that are mutually
# exclusive.  The first state is the current state, the
# following states can't be entered from that state.
BAD_TRANSITIONS=$(cat <<MSG
        INITIALIZE->SYNC
        RESTORE->SYNC
        INITIALIZE->RESTORE
        RESTORE->INITIALIZE
        READY->RESTORE
        READY->INITIALIZE
MSG
)

if [ -z "$(echo $VALID_STATES | grep $NEW_STATE)" ]; then
        echo "$NEW_STATE is not a valid state.  Valid states: $VALID_STATES"
        exit 1
fi

if [ "$STATE" == "$NEW_STATE" ]; then
        echo "State already set to $STATE."
        exit 0
fi

CONFLICT="$(echo $BAD_TRANSITIONS | grep -F "$STATE->$NEW_STATE")"

if [ -n "$CONFLICT" ]; then
        echo "Can't enter $NEW_STATE state when in $STATE state."
        exit 1
else
        echo "Setting state to $NEW_STATE..."
        echo "$NEW_STATE" > $SCRIPT_PATH/DB_STATE
fi