# A fonte padrao (AFM/WinAnsi) cobre acentuacao do portugues sem problema --
# confirmado por round-trip (texto acentuado sai identico depois de
# extraido de volta do PDF). O aviso e generico sobre Unicode amplo (CJK,
# emoji), que este app bilingue pt-BR/EN nunca usa.
Prawn::Fonts::AFM.hide_m17n_warning = true
