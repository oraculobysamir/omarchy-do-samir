-- Ver tudo: omarchy menu keybindings --print

-- Screenshot em SUPER+SHIFT+S (remove o Google Maps padrão); SUPER+ALT+D livre.
hl.unbind("SUPER + ALT + D")
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")

-- D2: push-to-talk do Voxtype em SUPER+H (segurar fala, soltar transcreve). Só SUPER+CTRL+H é usado pelo Omarchy.
o.bind("SUPER + H", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("SUPER + H", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- Log do Voxtype
o.bind("SUPER + SHIFT + V", "Voxtype log", "xdg-terminal-exec --app-id=TUI.float -e voxtype-log")

-- iniciar: launcher de sessão (SUPER+I); tarefas: retomar projeto/tarefa (SUPER+R)
o.bind("SUPER + I", "Launch apps", {
  launch = "xdg-terminal-exec --app-id=org.omarchy.iniciar -e iniciar",
  focus = "org.omarchy.iniciar",
})
o.bind("SUPER + R", "Retomar projeto/tarefa", {
  launch = "xdg-terminal-exec --app-id=org.omarchy.tarefas -e tarefas --janela",
  focus = "org.omarchy.tarefas",
})

-- Onda 2 (Deck): teclado na tela e Mosaico para o modo toque.
-- SUPER+CTRL+K era "Herdr keybindings" no Omarchy; o teclado na tela vale mais no GPD.
hl.unbind("SUPER + CTRL + K")
o.bind("SUPER + CTRL + K", "Teclado na tela", "gpd-osk toggle", { locked = true })
o.bind("SUPER + CTRL + M", "Mosaico (grade de apps)", "mosaico")
