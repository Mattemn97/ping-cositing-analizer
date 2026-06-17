@echo off
rem ===============================================================================
rem NOME SCRIPT:   Ping_Analyzer.bat
rem DESCRIZIONE:   Strumento di monitoraggio e analisi statistica del ping in tempo
rem                reale con interfaccia grafica tabellare nativa in Prompt dei Comandi.
rem CARATTERISTICHE:
rem                - Supporto multi-lingua automatico (Sistemi operativi IT / EN).
rem                - Configurazione guidata dei parametri di rete e di test (RF).
rem                - Storico dinamico degli ultimi 5 tentativi (Array-shifting).
rem                - Refresh dello schermo anti-cascata per un'interfaccia fissa.
rem REQUISITI:     Windows 7 o superiore, diritti utente standard.
rem ===============================================================================

:: -------------------------------------------------------------------------------
:: CONFIGURAZIONE AMBIENTE OPERATIVO
:: -------------------------------------------------------------------------------
:: Forza l'utilizzo della tabella codici UTF-8 (65001) per garantire la corretta
:: visualizzazione dei caratteri ASCII estesi usati per i bordi della tabella.
chcp 65001 >nul

:: Abilita l'Espansione Ritardata delle Variabili (!var! anziché %var%).
:: Fondamentale nei cicli (loop) per aggiornare e leggere il valore in tempo reale
:: delle statistiche all'interno della stessa esecuzione del blocco di codice.
setlocal enabledelayedexpansion

:input_setup
cls
echo ===============================================================================
echo                PROCEDURA GUIDATA DI CONFIGURAZIONE DEL TEST
echo ===============================================================================
echo.

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
:: Nota: Vengono azzerati qui per consentire il reset pulito in caso di riavvio del test.
set /a sent=0
set /a received=0
set /a lost=0
set /a total_time=0
set /a last_time=0
set /a avg_time=0

:: Inizializzazione dei registri di scorrimento (History Log degli ultimi 5 ping)
:: Valore 1 = Successo, Valore 0 = Fallito/Scaduto
set /a h1=0 & set /a h2=0 & set /a h3=0 & set /a h4=0 & set /a h5=0
set /a history_count=0

cls

:: -------------------------------------------------------------------------------
:: CORE LOOP - PROCESSO DI MONITORAGGIO CONTINUO
:: -------------------------------------------------------------------------------
:loop
:: Verifica se è stato raggiunto il tetto massimo di ping configurato dall'utente.
:: Se max_pings è 0, il controllo viene saltato permettendo il ciclo infinito.
if %max_pings% NEQ 0 (
    if !sent! GEQ %max_pings% goto end
)

:: Incremento del contatore dei pacchetti totali inviati
set /a sent+=1
set "ping_success=0"
set "curr_time=0"

:: Esecuzione del comando Ping nativo:
:: -n 1: Invia un singolo pacchetto per ciclo per calcolare la statistica istantanea.
:: -w %timeout_ms%: Applica il timeout inserito dall'utente.
:: findstr /i "TTL=": Filtra l'output trattenendo solo le righe di risposta andata a buon fine.
for /f "tokens=*" %%a in ('ping -n 1 -w %timeout_ms% !target_ip! 2^>nul ^| findstr /i "TTL="') do (
    set "ping_success=1"
    
    :: Scomposizione della riga di successo in token (parole) per estrarre la latenza.
    for %%b in (%%a) do (
        set "token=%%b"
        
        :: Caso OS Italiano: Cerca la stringa identificativa "durata="
        if "!token:~0,7!"=="durata=" (
            set "time_str=!token:durata=!"
            set "time_str=!time_str:ms=!"
            set /a curr_time=!time_str!
        )
        :: Caso OS Inglese: Cerca la stringa identificativa "time="
        if "!token:~0,5!"=="time=" (
            set "time_str=!token:time=!"
            set "time_str=!time_str:ms=!"
            set /a curr_time=!time_str!
        )
        :: Gestione delle eccezioni per latenze inferiori a 1 millisecondo (<1ms)
        if "!token:~0,7!"=="durata<" set "curr_time=0"
        if "!token:~0,5!"=="time<" set "curr_time=0"
    )
)

:: -------------------------------------------------------------------------------
:: ELABORAZIONE DATI E CALCOLO DELLE METRICHE
:: -------------------------------------------------------------------------------
if "!ping_success!"=="1" (
    set /a received+=1
    set "display_last=!curr_time! ms"
    set /a total_time+=!curr_time!
    :: Calcolo della media aritmetica (Divisione intera nativa di Windows)
    set /a avg_time=!total_time! / !received!
    set "h_curr=1"
) else (
    set /a lost+=1
    set "display_last=Richiesta Scaduta"
    set "h_curr=0"
)

:: Logica di Shifting (scorrimento a sinistra) per memorizzare gli ultimi 5 esiti.
:: Il dato più vecchio (h5) viene sovrascritto, ogni dato scala di un posto, h1 accoglie l'ultimo esito.
set /a h5=!h4!
set /a h4=!h3!
set /a h3=!h2!
set /a h2=!h1!
set /a h1=!h_curr!

:: Incrementa il divisore della cronologia breve fino a stabilizzarsi sul valore massimo di 5
if !history_count! LSS 5 set /a history_count+=1

:: Somma dei bit di successo nei registri per determinare il numero netto di ping riusciti negli ultimi 5
set /a last_5_success=!h1! + !h2! + !h3! + !h4! + !h5!

:: Calcolo matematico delle percentuali di successo e perdita sul totale inviato
set /a pct_received=(!received! * 100) / !sent!
set /a pct_lost=(!lost! * 100) / !sent!

:: -------------------------------------------------------------------------------
:: RENDERING INTERFACCIA GRAFICA (TABELLA CMD)
:: -------------------------------------------------------------------------------
:: Pulisce lo schermo per sovrascrivere i vecchi dati, evitando lo scorrimento verticale.
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
echo  [Premere CTRL+C per interrompere il monitoraggio]

:: Timeout tecnico di 1 secondo per distanziare l'invio dei pacchetti ICMP ed evitare il flooding di rete
timeout /t 1 >nul
goto loop

:: -------------------------------------------------------------------------------
:: SEZIONE DI FINE ACCUMULO / INTERAZIONE UTENTE PER NUOVO TEST
:: -------------------------------------------------------------------------------
:end
echo.
echo ══════════════════════════════════════════════════════════════
echo  Monitoraggio completato.
echo ══════════════════════════════════════════════════════════════
echo.

:: Gestione della scelta interattiva di ricominciare o uscire dal programma
set "scelta=N"
set /p scelta="Vuoi procedere con un'altra serie di misurazioni? (S/N) [Default: N]: "

:: Il flag "/i" rende il confronto insensibile alle maiuscole/minuscole (S accetta anche s)
if /i "%scelta%"=="S" (
    goto input_setup
)

echo.
echo Chiusura del programma in corso...
timeout /t 2 >nul
exit
