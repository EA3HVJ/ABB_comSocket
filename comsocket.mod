MODULE comSocket
!********************************************************************************
!	INTERFICIE DE COMUNICACIO ROBOT-PC AMB CONTROL REMOT VIA SOCKET TCP	*
!										*
!	Versio:		1.0							*
!	Data:		04/2017							*
!	Autor: 		Joan Planella Costa					*
!										*
!	Comandes Netcat per SO GNU/Linux:					*
!		PC Servidor:	$ nc -l -p PORT					*
!		PC Client:	$ nc IP_IRC5 PORT				*
!********************************************************************************

	!CONSTANTS INTERFICIE USUARI
	!Nom robot
	
	CONST string NOM_ROB:="<IRC5> ";
	
	!Missatges FlexPendant

	CONST string FP_TITOL:="INTERFICIE DE COMUNICACIO ROBOT-PC VIA TCP SOCKET";
	CONST string FP_PREGUNTA:="Selecciona qui vols emprar de servidor del socket";
	CONST string FP_RESP1_IRC5:="Controladora IRC5";
	CONST string FP_RESP2_PC:="Ordinador";
	CONST string FP_ESPERA:="Servidor en marxa. Esperant client...";
	CONST string FP_CON_ESTABLERTA:="Connexio establerta";
	CONST string FP_FI_COM:="S'ha tancant la connexio";
	CONST string FP_RESP_OK:="ACCEPTAR";

	!Missatges Socket TCP: main

	CONST string MSG_CON_ESTABLERTA:=NOM_ROB+"Connexio establerta\0A";
	CONST string MSG_COMANDA:=NOM_ROB+"Envia [PCctrl], [calibracio], [Load], [UnLoad] o crida un proces: ";
	CONST string MSG_COM_REBUDA:=NOM_ROB+"Comanda rebuda. Processant...\0A";
	CONST string MSG_RUTA:=NOM_ROB+"Ruta del fitxer [(discXarxa:)/dir/fitxer.mod]: ";
	CONST string MSG_ACC_REALITZADA:=NOM_ROB+"Accio realitzada\0A";

	!Missatges gestor d'errors

	CONST string MSG_ERR_PROC:=NOM_ROB+"ERROR: No s'ha trobat el proces\0A";
	CONST string MSG_ERR_LOAD1:=NOM_ROB+"ERROR: No s'ha trobat el fitxer\0A";
	CONST string MSG_ERR_LOAD2:=NOM_ROB+"ERROR: No s'ha carregat el modul perque ja es troba carregat\0A";
	CONST string MSG_ERR_LOAD3:=NOM_ROB+"ERROR: No s'ha pogut carregat el modul\0A";
	CONST string MSG_ERR_UNLOAD:=NOM_ROB+"ERROR: No s'ha trobat el fitxer o el modul esta en execucio\0A";

	!Missatges Socket TCP: PCctrl

	CONST string MSG_MPO:=NOM_ROB+"MOVIMENT PER ORDRE\0A";
	CONST string MSG_MOVES:=NOM_ROB+"Envia la comanda <MoveJ> o be <MoveL> si vols un moviment lineal: ";
	CONST string MSG_CMD_ERR:=NOM_ROB+"Comanda incorrecta. Escriu una nova comanda: ";
	CONST string MSG_ARG_ERR:=NOM_ROB+"Argument no valid. Escriu un nou argument: ";
	CONST string MSG_RANG_ERR:=NOM_ROB+"Posició fora de rang\0A";
	CONST string MSG_ARGS{6}:=[	NOM_ROB+"Moviment X (mm): ",
					NOM_ROB+"Moviment Y (mm): ", 
					NOM_ROB+"Moviment Z (mm): ",
					NOM_ROB+"Orientacio X (º): ",
					NOM_ROB+"Orientacio Y (º): ",
					NOM_ROB+"Orientacio Z (º): "];

	!Missatges Socket TCP: calibracio

	CONST string MSG_CAL:=NOM_ROB+"S'ha finalitzat el posicionament de calibracio amb exit\0A";

	!Codis error

	CONST num ERR_INSTRUC:=193;
	!********************************************************************************
  
	!Configura les IPs i el port que vols fer servir. Per defecte IPs SER1
	VAR string IP_IRC5:="192.168.125.1";
	VAR string IP_PC:="192.168.125.3";
	VAR num PORT_TCP:=1025;
	!********************************************************************************
  
	VAR num preguntaServidor:=0;
	VAR num fiCom:=0;
	VAR socketdev socketIRC5;
	VAR socketdev socketPC;
	VAR string stringRebut:="";
	VAR string instruccio:="";
	VAR bool accioOK;

	!Proces pricipal: establir connexio, carregar/descarregar moduls i crida processos
	PROC main()
		TPErase;
		TPWrite FP_TITOL;
		TPReadFK preguntaServidor,FP_PREGUNTA,FP_RESP1_IRC5,FP_RESP2_PC,stEmpty,stEmpty,stEmpty;

		TEST preguntaServidor
		CASE 1: !Servidor IRC5
			SocketCreate socketIRC5;
			SocketBind socketIRC5,IP_IRC5, PORT_TCP;
			SocketListen socketIRC5;
			TPWrite FP_ESPERA;
			!Per acceptar peticio de qualsevol origen esborra el camp \ClientAdress:=IP_PC
			SocketAccept socketIRC5, socketPC\ClientAddress:=IP_PC;

		CASE 2: !Servidor PC
			SocketCreate socketPC;
			SocketConnect socketPC, IP_PC, PORT_TCP;
		ENDTEST

		TPWrite FP_CON_ESTABLERTA;
		SocketSend socketPC\Str:=MSG_CON_ESTABLERTA;
		WHILE SocketGetStatus(socketPC)=SOCKET_CONNECTED DO
			SocketSend socketPC\Str:=MSG_COMANDA;
			SocketReceive socketPC\Str:=stringRebut;
			SocketSend socketPC\Str:=MSG_COM_REBUDA;
			instruccio:=StrPart(stringRebut, 1, StrLen(stringRebut)-1);
			IF instruccio="Load" OR instruccio="UnLoad" THEN
				accioOK:=TRUE;
				SocketSend socketPC\Str:=MSG_RUTA;
				SocketReceive socketPC\Str:=stringRebut;
				stringRebut:=StrPart(stringRebut, 1, StrLen(stringRebut)-1);
				%instruccio% stringRebut;
				IF accioOK=TRUE THEN
					SocketSend socketPC\Str:=MSG_ACC_REALITZADA;
				ENDIF
			ELSE
				%instruccio%;
			ENDIF
		ENDWHILE
		ERROR
			IF ERRNO=ERR_REFUNKPRC OR ERRNO=ERR_CALLPROC OR ERRNO=ERR_INSTRUC THEN
				SocketSend socketPC\Str:=MSG_ERR_PROC;
				TRYNEXT;
			ELSEIF ERRNO=ERR_FILNOTFND THEN
				SocketSend socketPC\Str:=MSG_ERR_LOAD1;
				accioOK:=FALSE;
				TRYNEXT;
			ELSEIF ERRNO=ERR_LOADED THEN
				SocketSend socketPC\Str:=MSG_ERR_LOAD2;
				accioOK:=FALSE;
				TRYNEXT;
			ELSEIF ERRNO=ERR_IOERROR OR ERRNO=ERR_PRGMEMFULL OR ERRNO=ERR_SYNTAX THEN
				accioOK:=FALSE;
				SocketSend socketPC\Str:=MSG_ERR_LOAD3;
				accioOK:=FALSE;
				TRYNEXT;
			ELSEIF ERRNO=ERR_UNLOAD THEN
				SocketSend socketPC\Str:=MSG_ERR_UNLOAD;
				accioOK:=FALSE;
				TRYNEXT;
			ELSEIF ERRNO=ERR_SOCK_CLOSED THEN
				SocketClose socketPC;
				IF preguntaServidor=1 THEN			
					SocketClose socketIRC5;
				ENDIF
				TPReadFK fiCom,FP_FI_COM,FP_RESP_OK,stEmpty,stEmpty,stEmpty,stEmpty;
				ExitCycle;
			ENDIF
	ENDPROC

	!Proces de control de posicio relatiu per moviment XYZ i orientacio XYZ
	PROC PCctrl()
		VAR robtarget posicio;
		VAR jointtarget comprovaPos;
		VAR num args{6}:=[0,0,0,0,0,0];
		VAR bool argOK;
		VAR bool posOK:=TRUE;

		posicio:=CRobT();
		SocketSend socketPC\Str:=MSG_MPO;
		SocketSend socketPC\Str:=MSG_MOVES;
		SocketReceive socketPC\Str:=stringRebut;
		instruccio:=StrPart(stringRebut, 1, StrLen(stringRebut)-1);
		WHILE instruccio <> "MoveJ" AND instruccio <> "MoveL" DO
			SocketSend socketPC\Str:=MSG_CMD_ERR;
			SocketReceive socketPC\Str:=stringRebut;
			instruccio:=StrPart(stringRebut, 1, StrLen(stringRebut)-1);
		ENDWHILE
		FOR i FROM 1 TO 6 DO
			SocketSend socketPC\Str:=MSG_ARGS{i};
			SocketReceive socketPC\Str:=stringRebut;
			stringRebut:=StrPart(stringRebut, 1, StrLen(stringRebut)-1);
			argOK := StrToVal(stringRebut,args{i});
			WHILE argOK=FALSE DO
				SocketSend socketPC\Str:=MSG_ARG_ERR;
				SocketReceive socketPC\Str:=stringRebut;
				stringRebut:=StrPart(stringRebut, 1, StrLen(stringRebut)-1);
				argOK:=StrToVal(stringRebut,args{i});
			ENDWHILE
		ENDFOR

		!Per evitar punts singulars descomentar una de les opcions
		SingArea \LockAxis4;
		!SingArea \Wrist;

        	comprovaPos:=CalcJointT (RelTool (posicio, args{1}, args{2}, args{3} \Rx:=args{4} \Ry:=args{5} \Rz:=args{6}), tool0);
		IF posOK=TRUE THEN
			%instruccio% RelTool (posicio, args{1}, args{2}, args{3} \Rx:=args{4} \Ry:=args{5} \Rz:=args{6}), v500, fine, tool0;
			SocketSend socketPC\Str:=MSG_ACC_REALITZADA;
		ENDIF
		ERROR
			IF ERRNO=ERR_ROBLIMIT THEN
				posOK:=FALSE;
				SocketSend socketPC\Str:=MSG_RANG_ERR;
				TRYNEXT;
			ELSEIF ERRNO=ERR_SOCK_CLOSED THEN
				SocketClose socketPC;
				IF preguntaServidor=1 THEN			
					SocketClose socketIRC5;
				ENDIF
				TPReadFK fiCom,FP_FI_COM,FP_RESP_OK,stEmpty,stEmpty,stEmpty,stEmpty;
				ExitCycle;
			ENDIF
	ENDPROC

	!Proces per posicionar robot a punt de calibracio
	PROC calibracio()
		MoveAbsJ [[0,0,0,0,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]\NoEOffs,v200,fine,tool0;
		SocketSend socketPC\Str:=MSG_CAL;
	ERROR
		IF ERRNO=ERR_SOCK_CLOSED THEN
			SocketClose socketPC;
			IF preguntaServidor=1 THEN			
				SocketClose socketIRC5;
			ENDIF
			TPReadFK fiCom,FP_FI_COM,FP_RESP_OK,stEmpty,stEmpty,stEmpty,stEmpty;
			ExitCycle;
		ENDIF
	ENDPROC
ENDMODULE
