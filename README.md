# ABB_comSocket
Interfície de comunicació Robot-PC amb control remot via Socket TCP

Descripció:
El fitxer comsocket.mod és un programa escrit en RAPID per a robots ABB.
S'ha provat amb un robot ABB IRB120 i la controladora IRC5 Compacta.
El programa implementa la comunicació entre el robot i un PC a través
de sockets TCP. El programa ha estat pensat per comunicar-se amb el PC a
través de l'aplicació Netcat.

Funcionament:
Escollim qui serà el servidor (robot o PC) i establim connexió. Aleshores
ens ofereix la possibilitat de cridar processos (callproc) o executar les
instruccions Load i UnLoad per carregar o descarregar mòduls de programa.
Ens ofereix dos processos implementats en aquest mòdul: posar el robot en
posició de calibració o fer moviments controlats des del PC [PCctrl].
PCctrl ens permet fer MoveJ o MoveL. El moviment és respecte la posició
actual del robot. Ens demanarà 6 arguments: desplaçament en mm d'X, Y i Z
i gir en graus d'X, Y i Z.

Crèdits:
Ha sigut escrit per Joan Planella Costa "EA3HVJ" per un mini-projecte del
mòdul de Robòtica del CFGS d'Automatització i Robòtica Industrial per
l'IES Narcís Xifra de Girona, Catalunya.
