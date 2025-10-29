/**
 * @description Service class for calculating and updating Account Health Scores
 */
public with sharing class AccountHealthService {
    
    /**
     * @description Updates Health Scores for specified Accounts based on Annual Revenue and Recent Wins
     * @param accountIds Set of Account IDs to update
     */
    public static void updateHealthScores(Set<Id> accountIds) {
        // Validate input
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        // Check read access
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new SecurityException('Insufficient permissions to read Account records');
        }
        
        // Query accounts with required fields
        List<Account> accountsToUpdate = [
            SELECT Id, AnnualRevenue, Last_90_Day_Wins__c, Health_Score__c
            FROM Account
            WHERE Id IN :accountIds
        ];
        
        // Calculate health scores for each account
        for (Account acc : accountsToUpdate) {
            Integer revenueScore = calculateRevenueScore(acc.AnnualRevenue);
            Integer recentWinsScore = calculateRecentWinsScore(acc.Last_90_Day_Wins__c);
            acc.Health_Score__c = revenueScore + recentWinsScore;
        }
        
        // Check update access and update accounts
        if (!accountsToUpdate.isEmpty()) {
            if (!Schema.sObjectType.Account.isUpdateable()) {
                throw new SecurityException('Insufficient permissions to update Account records');
            }
            update accountsToUpdate;
        }
    }
    
    /**
     * @description Calculates Revenue Score based on Annual Revenue
     * @param annualRevenue Annual Revenue amount
     * @return Integer score (0, 10, 30, or 50)
     */
    private static Integer calculateRevenueScore(Decimal annualRevenue) {
        // If AnnualRevenue is null or 0 → 0 points
        if (annualRevenue == null || annualRevenue == 0) {
            return 0;
        }
        
        // If AnnualRevenue > 0 and < 250,000 → 10 points
        if (annualRevenue > 0 && annualRevenue < 250000) {
            return 10;
        }
        
        // If AnnualRevenue ≥ 250,000 and < 1,000,000 → 30 points
        if (annualRevenue >= 250000 && annualRevenue < 1000000) {
            return 30;
        }
        
        // If AnnualRevenue ≥ 1,000,000 → 50 points
        if (annualRevenue >= 1000000) {
            return 50;
        }
        
        return 0;
    }
    
    /**
     * @description Calculates Recent Wins Score based on Last 90 Day Wins
     * @param last90DayWins Last 90 Day Wins amount
     * @return Integer score (0, 10, 30, or 50)
     */
    private static Integer calculateRecentWinsScore(Decimal last90DayWins) {
        // If Last_90_Day_Wins__c is null or 0 → 0 points
        if (last90DayWins == null || last90DayWins == 0) {
            return 0;
        }
        
        // If Last_90_Day_Wins__c > 0 and < 25,000 → 10 points
        if (last90DayWins > 0 && last90DayWins < 25000) {
            return 10;
        }
        
        // If Last_90_Day_Wins__c ≥ 25,000 and < 100,000 → 30 points
        if (last90DayWins >= 25000 && last90DayWins < 100000) {
            return 30;
        }
        
        // If Last_90_Day_Wins__c ≥ 100,000 → 50 points
        if (last90DayWins >= 100000) {
            return 50;
        }
        
        return 0;
    }
}
