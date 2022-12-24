# Author: Puneet Kakkar
# Must install: brew install reattach-to-user-namespace

export PATH=$PATH:/usr/local/bin

# abort if we're already inside a TMUX session
[ "$TMUX" == "" ] || exit 0

# startup a "default" session if none currently exists
# tmux has-session -t _default || tmux new-session -s _default -d

DEFAULT_TMUX_SESSION_NAME="base"

tmux has-session -t $DEFAULT_TMUX_SESSION_NAME 2>/dev/null

if [ "$?" -eq 1 ] ; then
  tmux new-session -s $DEFAULT_TMUX_SESSION_NAME -d
  echo "Create a default tmux session."
else
  echo "Default tmux session found."
fi


# present menu for user to choose which workspace to open
PS3="Please choose your session: "
options=($(tmux list-sessions -F "#S") "NEW SESSION" "BASH" "ZSH")
echo "Available sessions"
echo "------------------"
echo " "
select opt in "${options[@]}"
do
  case $opt in
    "NEW SESSION")
      read -p "Enter new session name: " SESSION_NAME
      tmux new -s "$SESSION_NAME"
      break
      ;;
    "BASH")
      bash --login
      break
      ;;
    "ZSH")
      zsh --login
      break
      ;;
    *)
      tmux attach-session -t $opt
      break
      ;;
  esac
done
