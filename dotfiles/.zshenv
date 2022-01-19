export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export MYBIN=$HOME/.bin
export GOPATH=$MYBIN/go
export CARGO_HOME=$MYBIN/cargo
export GNUPGHOME=$HOME/.gnupg
export PATH=$PATH:$HOME/.scripts:$CARGO_HOME/bin:$GOPATH/bin

export LESSHISTFILE=$XDG_CACHE_HOME/less/lesshst
export EDITOR=nvim
export GIT_EDITOR=nvim
export FZF_DEFAULT_OPTS="--height 40% --reverse --no-bold"
export CM_LAUNCHER=rofi
export ASDF_DIR=$MYBIN/asdf
export ASDF_CONFIG_FILE=$XDG_CACHE_HOME/asdf/asdfrc
export ASDF_DATA_DIR=$ASDF_DIR
export DOTNET_CLI_TELEMETRY_OPTOUT=1

export MOUNT0=/mnt/$USER/mount0
export MOUNT1=/mnt/$USER/mount1
export MOUNT2=/mnt/$USER/mount2
