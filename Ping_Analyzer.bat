@echo off
rem ===============================================================================
rem NOME SCRIPT:   Ping_Analyzer.bat
rem DESCRIZIONE:   Strumento di monitoraggio e analisi statistica del ping in tempo
rem                reale con interfaccia grafica tabellare e REPORTING SU FILE.
rem CARATTERISTICHE:
rem                - Salvataggio opzionale del log completo + statistiche a fine test.
rem                - Supporto multi-lingua automatico (Sistemi operativi IT / EN).
rem                - Configurazione guidata dei parametri di rete e di test (RF).
rem                - Storico dinamico degli ultimi 5 tentativi (Array-shifting).
rem                - Refresh dello schermo anti-cascata per un'interfaccia fissa.
rem ===============================================================================

:: -------------------------------------------------------------------------------
:: CONFIGURAZIONE AMBIENTE OPERATIVO
:: -------------------------------------------------------------------------------
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Definizione del percorso del file di log temporaneo di appoggio
set "temp_log=%TEMP%\ping_analyzer_capture.tmp"

:input_setup
cls
echo ===============================================================================
echo                PROCEDURA GUIDATA DI CONFIGURAZIONE DEL TEST
echo ===============================================================================
echo.

:: Rimozione di eventuali file temporanei residui da sessioni precedenti fallite
if exist "%temp_log%" del "%temp_log%"

:: 1. IP o Hostname di destinazione
set "target_ip=8.8.8.8"
set /p target_ip="[1/6] Inserisci l'IP o Host da pingare [Default: 8.8.8.8]: "

:: 2. Limite superiore dei tentativi (Soglia di arresto del ciclo)
set "max_pings=20"
set /p max_pings="[2/6] Numero massimo di ping (Inserisci 0 per ciclo infinito) [Default: 20]: "

:: 3. Soglia di tolleranza di rete (Timeout)
set "timeout_ms=6000"
set /p timeout_ms="[3/6] Tempo di attesa massimo risposta (in millisecondi) [Default: 6000]: "

:: 4. Metadato Scenario di Test: Vettore che subisce l'interferenza
set "vettore_vittima=Vettore_A"
set /p vettore_vittima="[4/6] Identificativo del Vettore Vittima [Default: Vettore_A]: "

:: 5. Metadato Scenario di Test: Vettore che genera l'interferenza
set "vettore_interferente=Vettore_B"
set /p vettore_interferente="[5/6] Identificativo del Vettore Interferente [Default: Vettore_B]: "

:: 6. Valore numerico dell'attenuazione impostata sul canale RF
set "attenuazione_db=0"
set /p attenuazione_db="[6/6] Livello di Attenuazione introdotto in prova (dB) [Default: 0]: "

:: -------------------------------------------------------------------------------
:: INIZIALIZZAZIONE / RESET DEI CONTATORI STATISTICI
:: -------------------------------------------------------------------------------
set /a sent=0
set /a received=0
set /a lost=0
set /a total_time=0
set /a last_time=0
set /a avg_time=0

:: Inizializzazione dei registri di scorrimento (History Log degli ultimi 5 ping)
set /a h1=0 & set /a h2=0 & set /a h3=0 & set /a h4=0 & set /a h5=0
set /a history_count=0

cls

:: -------------------------------------------------------------------------------
:: CORE LOOP - PROCESSO DI MONITORAGGIO CONTINUO
:: -------------------------------------------------------------------------------
:loop
if %max_pings% NEQ 0 (
    if !sent! GEQ %max_pings% goto end
)

set /a sent+=1
set "ping_success=0"
set "curr_time=0"

:: Esecuzione del comando Ping nativo con filtraggio della risposta
for /f "tokens=*" %%a in ('ping -n 1 -w %timeout_ms% !target_ip! 2^>nul ^| findstr /i "TTL="') do (
    set "ping_success=1"
    for %%b in (%%a) do (
        set "token=%%b"
        if "!token:~0,7!"=="durata=" (
            set "time_str=!token:durata=!"
            set "time_str=!time_str:ms=!"
            set /a curr_time=!time_str!
        )
        if "!token:~0,5!"=="time=" (
            set "time_str=!token:time=!"
            set "time_str=!time_str:ms=!"
            set /a curr_time=!time_str!
        )
        if "!token:~0,7!"=="durata<" set "curr_time=0"
        if "!token:~0,5!"=="time<" set "curr_time=0"
    )
)

:: -------------------------------------------------------------------------------
:: ELABORAZIONE DATI E SCRITTURA LOG TEMPORANEO
:: -------------------------------------------------------------------------------
set "timestamp=!time:~0,8!"

if "!ping_success!"=="1" (
    set /a received+=1
    set "display_last=!curr_time! ms"
    set /a total_time+=!curr_time!
    set /a avg_time=!total_time! / !received!
    set "h_curr=1"
    rem Scrittura nel file temporaneo di log
    echo [!timestamp!] Ping #!sent!: Successo - Ritardo: !curr_time! ms>>"%temp_log%"
) else (
    set /a lost+=1
    set "display_last=Richiesta Scaduta"
    set "h_curr=0"
    rem Scrittura nel file temporaneo di log caso fallito
    echo [!timestamp!] Ping #!sent!: FALLITO - Richiesta Scaduta>>"%temp_log%"
)

:: Logica di Shifting per gli ultimi 5 esiti
set /a h5=!h4!
set /a h4=!h3!
set /a h3=!h2!
set /a h2=!h1!
set /a h1=!h_curr!

if !history_count! LSS 5 set /a history_count+=1
set /a last_5_success=!h1! + !h2! + !h3! + !h4! + !h5!

:: Calcolo delle percentuali
set /a pct_received=(!received! * 100) / !sent!
set /a pct_lost=(!lost! * 100) / !sent!

:: -------------------------------------------------------------------------------
:: RENDERING INTERFACCIA GRAFICA (TABELLA CMD)
:: -------------------------------------------------------------------------------
cls
echo ╔═════════════════════════════════════════════════════════════════╗
echo ║                 STATISTICHE PING IN DIRETTA                     ║
echo ╠═════════════════════════════════════════════════════════════════╣
echo   Target:             !target_ip!                                             
echo   Timeout massimo:    !timeout_ms! ms                                
echo   Numero max ping:    !max_pings!                             
echo  ─────────────────────────────────────────────────────────────────
echo   Vettore Vittima:    !vettore_vittima!
echo   Vettore Interf.:    !vettore_interferente!
echo   Attenuazione:       !attenuazione_db! dB
echo  ─────────────────────────────────────────────────────────────────
echo   Pacchetti Inviati:  !sent!                                      
echo   Pacchetti Ricevuti: !received! (!pct_received!%%)               
echo   Pacchetti Persi:    !lost! (!pct_lost!%%)                       
echo  ─────────────────────────────────────────────────────────────────
echo   Ultimo Ritardo:     !display_last!                              
echo   Media Ritardo:      !avg_time! ms                               
echo  ─────────────────────────────────────────────────────────────────
echo   Ultimi 5 tentativi: !last_5_success! / !history_count! Riusciti 
echo ╚═════════════════════════════════════════════════════════════════╝

timeout /t 1 >nul
goto loop

:: -------------------------------------------------------------------------------
:: SEZIONE DI FINE SESSIONE / ESPORTAZIONE REPORT SU FILE
:: -------------------------------------------------------------------------------
:end
echo.
echo ══════════════════════════════════════════════════════════════
echo  Monitoraggio completato.
echo ══════════════════════════════════════════════════════════════
echo.

:: Richiesta di salvataggio del log della sessione corrente
set "save_scelta=N"
set /p save_scelta="Vuoi salvare i risultati di questa sessione su un file di testo? (S/N) [Default: N]: "

rem Utilizzo del salto condizionale GOTO anziché dell'IF nidificato per evitare i bug delle parentesi
if /i NOT "%save_scelta%"=="S" goto skip_save_file

echo.
set "output_file=ping_report.txt"
set /p output_file="Inserisci il nome del file [es. report1.txt] [Default: ping_report.txt]: "

rem Generazione dell'intestazione del report finale
echo =============================================================================== > "%output_file%"
echo   REPORT DI MONITORAGGIO RETE - Ping Analyzer Pro >> "%output_file%"
echo   Generato il: %date% alle %time% >> "%output_file%"
echo =============================================================================== >> "%output_file%"
echo   CONFIGURAZIONE SCENARIO TEST: >> "%output_file%"
echo   Target IP/Host:     !target_ip! >> "%output_file%"
echo   Vettore Vittima:    !vettore_vittima! >> "%output_file%"
echo   Vettore Interfer.:  !vettore_interferente! >> "%output_file%"
echo   Attenuazione (dB):  !attenuazione_db! dB >> "%output_file%"
echo ------------------------------------------------------------------------------- >> "%output_file%"
echo   CRONOLOGIA DETTAGLIATA DI OGNI PING ESEGUITO: >> "%output_file%"
echo ------------------------------------------------------------------------------- >> "%output_file%"

rem Riversa tutto il contenuto del file di cattura temporaneo nel file finale
if exist "%temp_log%" type "%temp_log%" >> "%output_file%"

rem Scrittura dei dati statistici aggregati a fondo file
echo ------------------------------------------------------------------------------- >> "%output_file%"
echo   STATISTICHE AGGREGATE FINALI: >> "%output_file%"
echo ------------------------------------------------------------------------------- >> "%output_file%"
echo   Totale Pacchetti Inviati:  !sent! >> "%output_file%"
echo   Totale Pacchetti Ricevuti: !received! (!pct_received!%%) >> "%output_file%"
echo   Totale Pacchetti Persi:    !lost! (!pct_lost!%%) >> "%output_file%"
echo   Latenza Media Calcolata:   !avg_time! ms >> "%output_file%"
echo =============================================================================== >> "%output_file%"

echo.
echo [+] Report salvato con successo in: %output_file%
echo.

:skip_save_file
:: Pulizia finale obbligatoria del file temporaneo dal sistema
if exist "%temp_log%" del "%temp_log%"

:: Richiesta di interazione per una nuova serie di misurazioni
set "scelta=N"
set /p scelta="Vuoi procedere con un'altra serie di misurazioni? (S/N) [Default: N]: "

if /i "%scelta%"=="S" (
    goto input_setup
)

echo.
echo Chiusura del programma in corso...
timeout /t 2 >nul
exit
