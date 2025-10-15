# MovieWatch

## Configurazione delle chiavi TMDB

1. Duplica `MovieWatch/Secrets.plist.sample` rinominandolo in `MovieWatch/Secrets.plist`.
2. Inserisci nel nuovo file il tuo token TMDB e (facoltativamente) lingua e regione personalizzate.
3. Aggiungi `Secrets.plist` al target `MovieWatch` da Xcode (`Add Files to "MovieWatch"...`) assicurandoti che sia incluso tra le risorse dell'app.
4. Non committare `MovieWatch/Secrets.plist`: il file è già ignorato da Git ed è pensato solo per gli ambienti locali.

Se `Secrets.plist` manca o il token è vuoto, l'app mostrerà l'errore `Token TMDB mancante`. In tal caso verifica di aver popolato correttamente il file e di averlo incluso nel bundle dell'app.
