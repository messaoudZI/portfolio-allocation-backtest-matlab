clc; clear; close all;

%% =========================================================
%  ESAME - Advanced Portfolio Management & Ingegneria Finanziaria
%  A.A. 2025-2026
% =========================================================

%% PARAMETRI ESOGENI
file_dati      = 'DATI.xlsx';
file_benchmark = 'Eurostoxx.xlsx';
rf             = 0.02 / 252;    % tasso risk free giornaliero (2% annuo / 252 giorni)
finestra       = 20;            % Rolling Window: guarda 20 giorni indietro
giorni_IS      = 120;           % In Sample: per trovare la strategia vincente
giorni_OS1     = 68;            % OS*: per identificare i top 15 titoli
numero_top     = 15;            % numero di titoli mantenuti per il Back Test

%% CARICAMENTO DATI
% Leggo i prezzi dal foglio Prices_giornalieri mantenendo i nomi originali
tabella    = readtable(file_dati, 'Sheet', 'Prices_giornalieri', 'VariableNamingRule', 'preserve');
nomi       = tabella.Properties.VariableNames;           % nomi dei titoli
rendimenti = diff(log(tabella{:,:}));                    % rendimenti logaritmici giornalieri
rendimenti = rendimenti(all(~isnan(rendimenti),2), :);   % elimina i giorni con dati mancanti
[T, N]     = size(rendimenti);                           % conta giorni e titoli (codice generico)
giorni_OS2 = T - giorni_IS - giorni_OS1;                 % Back Test calcolato automaticamente

% Leggo il benchmark Eurostoxx per il confronto nella Parte C
dati_bench = readmatrix(file_benchmark, 'Sheet', 'Best benchmark');
benchmark  = dati_bench(dati_bench ~= 0) / 100;          % elimina weekend e converte in decimale
benchmark  = benchmark(end - giorni_OS2 + 1 : end);      % allinea con il periodo OS**

% Nomi delle 5 strategie (per console e grafici)
nomi_strat = {'Equally Weighted', 'Mean Variance', 'Global Min Variance', ...
              'Risk Parity', 'Most Diversified Portfolio'};

fprintf('Titoli:%d | IS=%d | OS*=%d | OS**=%d\n\n', N, giorni_IS, giorni_OS1, giorni_OS2);

%% =========================================================
%  PARTE A — Rolling Window: identificare la strategia vincente
% =========================================================
fprintf('=== PARTE A ===\n');

% Prendo i primi 120 giorni In Sample (periodo di apprendimento)
rendimenti_IS  = rendimenti(1:giorni_IS, :);

% Matrice vuota 5x100: 5 righe (strategie) e 100 colonne (finestre)
sharpe_rolling = zeros(5, giorni_IS - finestra);

% Rolling Window: la finestra di 20 giorni scorre di un giorno alla volta
for finestra_corrente = 1:giorni_IS - finestra

    % Estraggo i 20 giorni della finestra corrente (per stimare)
    dati_stima         = rendimenti_IS(finestra_corrente : finestra_corrente + finestra - 1, :);

    % Prendo il giorno successivo alla finestra (per testare out-of-sample)
    rendimento_domani  = rendimenti_IS(finestra_corrente + finestra, :)';

    % Matrice di covarianza (rischio). Aggiungo 1e-8 sulla diagonale per stabilita' numerica
    matrice_covarianza = cov(dati_stima, 1) + 1e-8*eye(N);

    % Medie dei rendimenti (rendimento atteso)
    medie_titoli       = mean(dati_stima)';

    % Testo le 5 strategie e salvo lo Sharpe di ognuna
    for numero_strategia = 1:5
        [~, ~, ~, sharpe_rolling(numero_strategia, finestra_corrente), ~] = ...
            strategia(numero_strategia, matrice_covarianza, medie_titoli, rendimento_domani, rf);
    end
end

% Media degli Sharpe su tutte le finestre (mean con 2 = media per riga)
sharpe_medio            = mean(sharpe_rolling, 2);

% La strategia con lo Sharpe medio piu' alto e' la vincente
[~, strategia_vincente] = max(sharpe_medio);

fprintf('VINCENTE: %s\n\n', nomi_strat{strategia_vincente});

% Grafico a barre: le 5 strategie, la vincente evidenziata in rosso
figure('Name','A','Units','normalized','OuterPosition',[0 0 1 1]);
hold on; grid on;
for numero_strategia = 1:5
    if numero_strategia == strategia_vincente
        colore = [.9 .1 .1];   % rosso per la vincente
    else
        colore = [.3 .5 .8];   % blu per le altre
    end
    bar(numero_strategia, sharpe_medio(numero_strategia), 'FaceColor', colore, 'EdgeColor', 'k');
end
set(gca, 'XTick', 1:5, 'XTickLabel', nomi_strat, 'XTickLabelRotation', 15);
ylabel('Sharpe medio');
title(sprintf('PARTE A — Vincente: %s', nomi_strat{strategia_vincente}), 'FontWeight', 'bold');
hold off;

%% =========================================================
%  PARTE B — Mappatura pesi OS*: matrice + vettore delle medie
% =========================================================
fprintf('=== PARTE B ===\n');

% Prendo i 68 giorni di monitoraggio (dopo l'In Sample)
rendimenti_monitoraggio = rendimenti(giorni_IS+1 : giorni_IS+giorni_OS1, :);

% Numero di finestre possibili nel periodo di monitoraggio
numero_finestre_B = giorni_OS1 - finestra;

% Matrice vuota per salvare i pesi: N titoli x numero finestre
matrice_pesi = zeros(N, numero_finestre_B);

% Rolling Window: applico SOLO la strategia vincente su ogni finestra
for finestra_corrente = 1:numero_finestre_B

    % Estraggo i 20 giorni della finestra corrente
    dati_stima         = rendimenti_monitoraggio(finestra_corrente : finestra_corrente+finestra-1, :);

    % Giorno successivo alla finestra
    rendimento_domani  = rendimenti_monitoraggio(finestra_corrente+finestra, :)';

    % Covarianza (con stabilita' numerica) e medie della finestra
    matrice_covarianza = cov(dati_stima, 1) + 1e-8*eye(N);
    medie_titoli       = mean(dati_stima)';

    % Calcolo i pesi con la strategia vincente trovata nella Parte A
    [pesi_ottimali, ~, ~, ~, ~] = strategia(strategia_vincente, matrice_covarianza, ...
                                             medie_titoli, rendimento_domani, rf);

    % Salvo i pesi nella colonna corrispondente alla finestra
    matrice_pesi(:, finestra_corrente) = pesi_ottimali;
end

% Vettore delle medie: per ogni titolo, la media dei pesi su tutte le finestre
pesi_medi = mean(matrice_pesi, 2);

% Ordino i titoli dal peso medio piu' grande al piu' piccolo
[pesi_ordinati, ordine_decrescente] = sort(pesi_medi, 'descend');
titoli_ordinati                     = nomi(ordine_decrescente);

% Stampo la classifica dei titoli, con i top 15 marcati con asterisco
fprintf('\nTitoli per peso medio decrescente:\n');
for posizione = 1:N
    etichetta = '';
    if posizione <= numero_top, etichetta = ' *'; end
    fprintf('  %2d. %-30s %.6f%s\n', posizione, titoli_ordinati{posizione}, ...
            pesi_ordinati(posizione), etichetta);
end
fprintf('\n(* = top %d per Back Test)\n\n', numero_top);

% Grafico a barre: pesi medi di ogni titolo
figure('Name','B','Units','normalized','OuterPosition',[0 0 1 1]);
hold on; grid on;
for posizione = 1:N
    if posizione <= numero_top
        colore_barra = [.1 .7 .1];   % verde = top 15 selezionati
    else
        colore_barra = [.2 .4 .8];   % blu = titoli esclusi
    end
    bar(posizione, pesi_ordinati(posizione), 'FaceColor', colore_barra, 'EdgeColor', 'k');
end
xline(numero_top + .5, 'r--', 'LineWidth', 2);   % linea che separa i top 15
set(gca, 'XTick', 1:N, 'XTickLabel', titoli_ordinati, 'XTickLabelRotation', 45, 'FontSize', 7);
title(sprintf('PARTE B — Pesi Medi OS* | %s', nomi_strat{strategia_vincente}), ...
      'FontSize', 12, 'FontWeight', 'bold');
ylabel('Peso Medio');
hold off;

%% =========================================================
%  PARTE C — Back Test top 15 con finestra sempre aggiornata
% =========================================================
fprintf('=== PARTE C ===\n');

% Prendo solo i 15 titoli con il peso medio maggiore (dalla Parte B)
rendimenti_migliori       = rendimenti(:, ordine_decrescente(1:numero_top));
rendimento_giornaliero_bt = zeros(giorni_OS2, 1);

% Back Test: per ogni giorno la finestra si aggiorna con i dati piu' recenti
for giorno = 1:giorni_OS2

    giorno_corrente   = giorni_IS + giorni_OS1 + giorno;      % giorno di oggi
    inizio_finestra   = max(giorno_corrente - finestra, 1);   % 20 giorni prima
    dati_stima        = rendimenti_migliori(inizio_finestra : giorno_corrente-1, :);
    rendimento_domani = rendimenti_migliori(giorno_corrente, :)';

    % Covarianza (con stabilita' numerica) e medie sui 15 titoli
    matrice_covarianza = cov(dati_stima, 1) + 1e-8*eye(numero_top);
    medie_titoli       = mean(dati_stima)';

    % Ricalcolo i pesi con la strategia vincente
    [pesi_oggi, ~, ~, ~, ~] = strategia(strategia_vincente, matrice_covarianza, ...
                                         medie_titoli, rendimento_domani, rf);

    % Rendimento realizzato nel giorno corrente
    rendimento_giornaliero_bt(giorno) = rendimento_domani' * pesi_oggi;
end

% Performance: rendimento cumulato del portafoglio e del benchmark
cumulato_portafoglio = cumprod(1 + rendimento_giornaliero_bt);
cumulato_benchmark   = cumprod(1 + benchmark);

fprintf('Rendimento cumulato : %+.2f%%\n', (cumulato_portafoglio(end)-1)*100);
fprintf('Benchmark cumulato  : %+.2f%%\n\n', (cumulato_benchmark(end)-1)*100);

% Grafico: portafoglio Top 15 contro benchmark Eurostoxx
figure('Name','C','Units','normalized','OuterPosition',[0 0 1 1]);
hold on; grid on;
plot(cumulato_portafoglio, 'b-', 'LineWidth', 2.5, ...
     'DisplayName', sprintf('Top %d | %s', numero_top, nomi_strat{strategia_vincente}));
plot(cumulato_benchmark, 'r--', 'LineWidth', 2, 'DisplayName', 'Benchmark Eurostoxx');
yline(1, 'k:', 'HandleVisibility', 'off');
legend('Location', 'bestoutside', 'FontSize', 11);
xlabel('Giorni OS**');
ylabel('Valore (1 euro investito)');
title(sprintf('PARTE C — Back Test | Cumulato = %.2f%%', (cumulato_portafoglio(end)-1)*100), ...
      'FontSize', 13, 'FontWeight', 'bold');
hold off;

%% =========================================================
%  FUNZIONI
% =========================================================

function [pesi_ottimali, rendimento, varianza, sharpe_atteso, sharpe_effettivo] = ...
         strategia(numero_strategia, matrice_covarianza, medie_titoli, rendimento_domani, tasso_rf)

    numero_attivi = length(medie_titoli);
    vettore_uno   = ones(numero_attivi, 1);

    switch numero_strategia

        case 1  % Equally Weighted: stesso peso per ogni titolo (1/N)
            pesi_ottimali = vettore_uno / numero_attivi;

        case 2  % Mean Variance Constraint: massimizza il rapporto rendimento/rischio
            pesi_grezzi   = max(matrice_covarianza \ (medie_titoli - tasso_rf*vettore_uno), 0);
            pesi_ottimali = pesi_grezzi / sum(pesi_grezzi);

        case 3  % Global Min Variance: minimizza la varianza del portafoglio
            pesi_grezzi   = max(matrice_covarianza \ vettore_uno, 0);
            pesi_ottimali = pesi_grezzi / sum(pesi_grezzi);

        case 4  % Risk Parity: ogni titolo contribuisce ugualmente al rischio totale
            pesi_ottimali = vettore_uno / numero_attivi;
            for iterazione = 1:3000
                varianza_portafoglio = pesi_ottimali' * matrice_covarianza * pesi_ottimali;
                contributo_rischio   = pesi_ottimali .* (matrice_covarianza * pesi_ottimali);
                pesi_nuovi = max(pesi_ottimali .* varianza_portafoglio ./ ...
                                 (numero_attivi * contributo_rischio), 1e-12);
                pesi_nuovi = pesi_nuovi / sum(pesi_nuovi);
                if norm(pesi_nuovi - pesi_ottimali) < 1e-10, break; end
                pesi_ottimali = pesi_nuovi;
            end
            pesi_ottimali = pesi_nuovi;

        case 5  % Most Diversified Portfolio: massimizza la diversificazione
            volatilita_singoli = sqrt(diag(matrice_covarianza));
            pesi_grezzi        = max(matrice_covarianza \ volatilita_singoli, 0);
            pesi_ottimali      = pesi_grezzi / sum(pesi_grezzi);
    end

    % Sicurezza: se i pesi sono tutti nulli, uso Equally Weighted
    if sum(pesi_ottimali) < 1e-10
        pesi_ottimali = vettore_uno / numero_attivi;
    end

    rendimento       = medie_titoli' * pesi_ottimali;                       % rendimento atteso
    varianza         = pesi_ottimali' * matrice_covarianza * pesi_ottimali; % varianza portafoglio
    sharpe_atteso    = rendimento / sqrt(varianza);                          % Sharpe stimato
    sharpe_effettivo = rendimento_domani' * pesi_ottimali / sqrt(varianza);  % Sharpe realizzato
end
