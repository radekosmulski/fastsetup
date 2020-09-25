cat << 'EOF' >> ~/.tmux.conf
set -g prefix C-f
bind C-f send-prefix
unbind C-b

set -s escape-time 1 # speeds up exiting edit mode in vim
set -g base-index 1
setw -g pane-base-index 1
set -g status-left-length 40

bind r source-file ~/.tmux.conf \; display "Reloaded!"
bind | split-window -h
bind - split-window -v
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5
EOF
