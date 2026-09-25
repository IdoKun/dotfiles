ZSH=$HOME/.oh-my-zsh

# You can change the theme with another one from https://github.com/robbyrussell/oh-my-zsh/wiki/themes
ZSH_THEME="robbyrussell"

# Useful oh-my-zsh plugins for Le Wagon bootcamps
plugins=(git gitfast last-working-dir common-aliases zsh-syntax-highlighting history-substring-search pyenv direnv)

# Add the omz ssh-agent plugin for WSL / Linux only (macOS handles this through Keychain in ~/.ssh/config)
case "$(uname -s)" in
  Darwin) ;;
  Linux)  plugins+=('ssh-agent') ;;
esac

# (macOS-only) Prevent Homebrew from reporting - https://github.com/Homebrew/brew/blob/master/docs/Analytics.md
export HOMEBREW_NO_ANALYTICS=1

# Disable warning about insecure completion-dependent directories
ZSH_DISABLE_COMPFIX=true

# Actually load Oh-My-Zsh
source "${ZSH}/oh-my-zsh.sh"
unalias rm # No interactive rm by default (brought by plugins/common-aliases)
unalias lt # we need `lt` for https://github.com/localtunnel/localtunnel

# Load rbenv if installed (to manage your Ruby versions)
export PATH="${HOME}/.rbenv/bin:${PATH}" # Needed for Linux/WSL
type -a rbenv > /dev/null && eval "$(rbenv init -)"

# Load pyenv (to manage your Python versions)
# Uncomment the next lines if you still run a pyenv based setup
# export PYENV_VIRTUALENV_DISABLE_PROMPT=1
# type -a pyenv > /dev/null && eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init - 2> /dev/null)" && RPROMPT+='[🐍 $(pyenv version-name)]'

# Load nvm (to manage your node versions)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Call `nvm use` automatically in a directory with a `.nvmrc` file
autoload -U add-zsh-hook
load-nvmrc() {
  if nvm -v &> /dev/null; then
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use --silent
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      nvm use default --silent
    fi
  fi
}
type -a nvm > /dev/null && add-zsh-hook chpwd load-nvmrc
type -a nvm > /dev/null && load-nvmrc

# Rails and Ruby uses the local `bin` folder to store binstubs.
# So instead of running `bin/rails` like the doc says, just run `rails`
# Same for `./node_modules/.bin` and nodejs
export PATH="./bin:./node_modules/.bin:${PATH}:/usr/local/sbin"

# Store your own aliases in the ~/.aliases file and load the here.
[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"

# Encoding stuff for the terminal
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export BUNDLER_EDITOR=code
export EDITOR=code

# Set ipdb as the default Python debugger
export PYTHONBREAKPOINT=ipdb.set_trace
#export PYTHONPATH="/Users/thekunhome/code/IdoKun/data-challenges/04-Decision-Science:$PYTHONPATH"
export GOOGLE_APPLICATION_CREDENTIALS="/Users/thekunhome/code/IdoKun/gcp/le-wagon-ds23021983-4919c49f7ae5.json"
eval "$(direnv hook zsh)"
export GOOGLE_APPLICATION_CREDENTIALS=/Users/thekunhome/Code/IdoKun/gcp/le-wagon-bootcamp-1014-6d370a9f44ca.json

eval "$(/opt/homebrew/bin/brew shellenv)"

# The next line setup for le wagon Olist
#export PYTHONPATH="/Users/thekunhome/Code/IdoKun/Le-Wagon/1945-DS-PT-Online-Ben/007-Olist/:$PYTHONPATH"
#export PYTHONPATH="/Users/thekunhome/code/lewagon/04-Decision-Science/01-Project-Setup/data-context-and-setup:$PYTHONPATH"
#Batch 2332 Berlin
export PYTHONPATH="/Users/thekunhome/code/lewagon/03-Decision-Science:$PYTHONPATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/thekunhome/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/thekunhome/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/thekunhome/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/thekunhome/google-cloud-sdk/completion.zsh.inc'; fi

export PATH="$HOME/google-cloud-sdk/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export GOOGLE_APPLICATION_CREDENTIALS=/Users/thekunhome/Code/IdoKun/gcp/le-wagon-bootcamp-475211-8588607da502.json


# -----------------------------------------------------------------------------
# AI-powered Git Commit Function
# Copy paste this gist into your ~/.bashrc or ~/.zshrc to gain the `gcm` command. It:
# 1) gets the current staged changed diff
# 2) sends them to an LLM to write the git commit message
# 3) allows you to easily accept, edit, regenerate, cancel
# But - just read and edit the code however you like
# the `llm` CLI util is awesome, can get it here: https://llm.datasette.io/en/stable/

unalias gcm  # Remove the alias from oh-my-zsh's git plugin to avoid conflicts
gcm() {
    # Function to generate commit message
    generate_commit_message() {
        git diff --cached | llm "
Below is a diff of all staged changes, coming from the command:
\`\`\`
git diff --cached
\`\`\`
Please generate a concise, one-line commit message for these changes."
    }

    # Function to read user input compatibly with both Bash and Zsh
    read_input() {
        if [ -n "$ZSH_VERSION" ]; then
            echo -n "$1"
            read -r REPLY
        else
            read -p "$1" -r REPLY
        fi
    }

    # Main script
    echo "Generating AI-powered commit message..."
    commit_message=$(generate_commit_message)

    while true; do
        echo -e "\nProposed commit message:"
        echo "$commit_message"

        read_input "Do you want to (a)ccept, (e)dit, (r)egenerate, or (c)ancel? "
        choice=$REPLY

        case "$choice" in
            a|A )
                if git commit -m "$commit_message"; then
                    echo "Changes committed successfully!"
                    return 0
                else
                    echo "Commit failed. Please check your changes and try again."
                    return 1
                fi
                ;;
            e|E )
                read_input "Enter your commit message: "
                commit_message=$REPLY
                if [ -n "$commit_message" ] && git commit -m "$commit_message"; then
                    echo "Changes committed successfully with your message!"
                    return 0
                else
                    echo "Commit failed. Please check your message and try again."
                    return 1
                fi
                ;;
            r|R )
                echo "Regenerating commit message..."
                commit_message=$(generate_commit_message)
                ;;
            c|C )
                echo "Commit cancelled."
                return 1
                ;;
            * )
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Private env (not in this repo)
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"
