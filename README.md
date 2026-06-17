# 📊 Ping Analyzer

`Ping Analyzer` è uno script Batch (`.bat`) leggero, interattivo e standalone per Windows, progettato per il monitoraggio avanzato della latenza di rete e l'analisi statistica in tempo reale. 

A differenza del classico comando `ping` a cascata, questo strumento pulisce lo schermo a ogni ciclo e impagina i dati all'interno di una **tabella grafica dinamica** direttamente nel Prompt dei Comandi (CMD). Inoltre, include parametri specifici per scenari di test in radiofrequenza (RF) e analisi delle interferenze.

---

## ✨ Caratteristiche Principali

* **📺 Interfaccia Tabellare Dinamica:** Aggiornamento dei dati sul posto (refresh fisso) senza scorrimento verticale infinito.
* **🌍 Supporto Multi-lingua Automatico:** Algoritmo di parsing compatibile sia con sistemi operativi Windows in **Italiano** (`durata=`) che in **Inglese** (`time=`).
* **📡 Ottimizzato per Test RF & Interferenze:** Campi di input dedicati per tracciare scenari di attenuazione (dB) e vettori di segnale durante i test empirici.
* **📈 Statistiche Avanzate in Tempo Reale:** Calcolo automatico di pacchetti inviati/ricevuti/persi, relative percentuali e media aritmetica della latenza.
* **⏱️ Cronologia Breve (Rolling Window):** Monitoraggio visivo dello stato degli **ultimi 5 tentativi** per identificare al volo micro-interruzioni o jitter.
* **♻️ Loop Interattivo:** Possibilità di avviare una nuova sessione di misurazione con parametri differenti al termine del test, senza dover riaprire lo script.

---

## 🛠️ Parametri di Configurazione

All'avvio, la procedura guidata ti permetterà di configurare i seguenti parametri (tutti dotati di un valore di default preimpostato premendo semplicemente `Invio`):

| Parametro | Descrizione | Valore di Default |
| :--- | :--- | :--- |
| **IP / Host Target** | L'indirizzo di rete o dominio da monitorare. | `8.8.8.8` |
| **Numero Max Ping** | Quanti pacchetti inviare prima di fermarsi (`0` per ciclo infinito). | `20` |
| **Timeout (ms)** | Tempo massimo di attesa per singolo pacchetto prima di considerarlo perso. | `6000` |
| **Vettore Vittima** | Stringa identificativa del canale/vettore che subisce l'interferenza. | `Vettore_A` |
| **Vettore Interferente** | Stringa identificativa del canale/vettore sorgente del disturbo. | `Vettore_B` |
| **Attenuazione (dB)** | Livello di attenuazione o guadagno introdotto nella prova fisica. | `0` |

---

## 🚀 Installazione e Utilizzo

Non è richiesta alcuna installazione, lo script è nativo e standalone.

1. Scarica il file `Ping_Analyzer.bat` da questa repository (oppure clona la repo).
2. Fai doppio clic sul file `.bat` per avviarlo.
3. Segui i passaggi guidati inserendo i dati richiesti o premendo `Invio` per usare i default.
4. Per interrompere il test in qualsiasi momento, premi `CTRL + C`.

```bash
# Per clonare la repository tramite terminale
git clone [https://github.com/tuo-username/ping-analyzer-pro.git](https://github.com/tuo-username/ping-analyzer-pro.git)

```

---

## 📺 Anteprima dell'Interfaccia

Ecco come si presenta il terminale durante l'esecuzione del monitoraggio:

```text
╔═════════════════════════════════════════════════════════════════╗
║                 STATISTICHE PING IN DIRETTA                     ║
╠═════════════════════════════════════════════════════════════════╣
  Target:             8.8.8.8                                             
  Timeout massimo:    6000 ms                                
  Numero max ping:    20                             
 ─────────────────────────────────────────────────────────────────
  Vettore Vittima:    Vettore_A
  Vettore Interf.:    Vettore_B
  Attenuazione:       10 dB
 ─────────────────────────────────────────────────────────────────
  Pacchetti Inviati:  12                                      
  Pacchetti Ricevuti: 11 (91%)               
  Pacchetti Persi:    1 (9%)                       
 ─────────────────────────────────────────────────────────────────
  Ultimo Ritardo:     14 ms                              
  Media Ritardo:      15 ms                               
 ─────────────────────────────────────────────────────────────────
  Ultimi 5 tentativi: 4 / 5 Riusciti 
╚═════════════════════════════════════════════════════════════════╝
 [Premere CTRL+C per interrompere il monitoraggio]

```

---

## ⚙️ Dettagli Tecnici Notevoli

> **Codifica dei caratteri:** Lo script esegue il comando `chcp 65001` per forzare il terminale Windows a utilizzare la codifica UTF-8. Questo impedisce la corruzione visiva dei bordi della tabella ASCII su qualsiasi sistema.
> **Espansione Ritardata:** Viene impiegato il costrutto `setlocal enabledelayedexpansion` per consentire l'aggiornamento dinamico delle variabili matematiche (es. i contatori e le percentuali) all'interno dei cicli condizionali e di parsing.

## 🤝 Contributi

Le pull request sono benvenute. Per modifiche importanti, apri prima un'issue per discutere di cosa vorresti cambiare.
