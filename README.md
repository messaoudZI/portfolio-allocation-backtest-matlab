# portfolio-allocation-backtest-matlab
# Portfolio Allocation Backtest (MATLAB)

Projet d'Advanced Portfolio Management & Ingénierie Financière (A.A. 2025-2026).

## Objectif
Comparer 5 stratégies d'allocation, retenir la meilleure, sélectionner les 15 meilleurs titres puis tester le portefeuille out-of-sample face à l'Euro Stoxx.

## Stratégies
- Equally Weighted
- Mean-Variance (long-only)
- Global Minimum Variance (long-only)
- Risk Parity (algorithme itératif)
- Most Diversified Portfolio

## Méthodologie
| Étape | Période | Description |
|---|---|---|
| A | In-sample, 120 jours | Rolling window de 20 jours, choix de la stratégie au Sharpe moyen le plus élevé |
| B | OS*, 68 jours | Pesos moyens de la stratégie gagnante, sélection du top 15 |
| C | OS**, reste | Backtest avec réestimation quotidienne vs benchmark Euro Stoxx |

## Résultats
![Partie A](images/partie_A.png)
![Partie B](images/partie_B.png)
![Partie C](images/Screenshot (323).png)


## Utilisation
1. Placer `DATI.xlsx` (feuille `Prices_giornalieri`) et `Eurostoxx.xlsx` (feuille `Best benchmark`) dans le dossier.
2. Lancer le script dans MATLAB (R2019b ou plus récent).

## Limites
- Fenêtre d'estimation courte (20 jours)
- Pas de coûts de transaction
- Données non incluses (usage académique)

## Auteur
ZINA MESSAOUD, [LinkedIn]((https://www.linkedin.com/in/zina-messaoud-5922b13b6/?isSelfProfile=true))
