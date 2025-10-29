/**
 * @description Test class for AccountHealthService
 */
@IsTest
private class AccountHealthServiceTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts covering all revenue and wins buckets
        List<Account> testAccounts = new List<Account>();
        
        // Account 1: High Revenue (≥1M) + High Wins (≥100K) = 50+50 = 100
        testAccounts.add(new Account(
            Name = 'High Revenue High Wins Account',
            AnnualRevenue = 1500000,
            Last_90_Day_Wins__c = 150000
        ));
        
        // Account 2: Mid Revenue (≥250K, <1M) + Low Wins (>0, <25K) = 30+10 = 40
        testAccounts.add(new Account(
            Name = 'Mid Revenue Low Wins Account',
            AnnualRevenue = 500000,
            Last_90_Day_Wins__c = 15000
        ));
        
        // Account 3: Low Revenue (>0, <250K) + No Wins (0) = 10+0 = 10
        testAccounts.add(new Account(
            Name = 'Low Revenue No Wins Account',
            AnnualRevenue = 100000,
            Last_90_Day_Wins__c = 0
        ));
        
        // Account 4: No Revenue (0) + No Wins (null) = 0+0 = 0
        testAccounts.add(new Account(
            Name = 'No Revenue No Wins Account',
            AnnualRevenue = 0,
            Last_90_Day_Wins__c = null
        ));
        
        // Account 5: Edge case - exactly 250K revenue + exactly 25K wins = 30+30 = 60
        testAccounts.add(new Account(
            Name = 'Edge Case Revenue Wins Account',
            AnnualRevenue = 250000,
            Last_90_Day_Wins__c = 25000
        ));
        
        // Account 6: Edge case - exactly 1M revenue + exactly 100K wins = 50+50 = 100
        testAccounts.add(new Account(
            Name = 'Edge Case High Account',
            AnnualRevenue = 1000000,
            Last_90_Day_Wins__c = 100000
        ));
        
        // Account 7: Low Revenue + Mid Wins (≥25K, <100K) = 10+30 = 40
        testAccounts.add(new Account(
            Name = 'Low Revenue Mid Wins Account',
            AnnualRevenue = 50000,
            Last_90_Day_Wins__c = 60000
        ));
        
        // Account 8: Null revenue + high wins = 0+50 = 50
        testAccounts.add(new Account(
            Name = 'Null Revenue High Wins Account',
            AnnualRevenue = null,
            Last_90_Day_Wins__c = 200000
        ));
        
        insert testAccounts;
    }
    
    /**
     * @description Test updateHealthScores method with valid account IDs
     */
    @IsTest
    static void testUpdateHealthScores_AllBuckets() {
        // Query test accounts
        List<Account> accounts = [
            SELECT Id, Name, AnnualRevenue, Last_90_Day_Wins__c
            FROM Account
            ORDER BY Name
        ];
        
        // Collect account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Test the service method
        Test.startTest();
        AccountHealthService.updateHealthScores(accountIds);
        Test.stopTest();
        
        // Query updated accounts
        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account acc : [SELECT Id, Name, Health_Score__c FROM Account WHERE Id IN :accountIds]) {
            accountsByName.put(acc.Name, acc);
        }
        
        // Assert Account 1: 50+50 = 100
        Account acc1 = accountsByName.get('High Revenue High Wins Account');
        System.assertEquals(100, acc1.Health_Score__c, 'High Revenue (≥1M) + High Wins (≥100K) should equal 100');
        
        // Assert Account 2: 30+10 = 40
        Account acc2 = accountsByName.get('Mid Revenue Low Wins Account');
        System.assertEquals(40, acc2.Health_Score__c, 'Mid Revenue (≥250K, <1M) + Low Wins (>0, <25K) should equal 40');
        
        // Assert Account 3: 10+0 = 10
        Account acc3 = accountsByName.get('Low Revenue No Wins Account');
        System.assertEquals(10, acc3.Health_Score__c, 'Low Revenue (>0, <250K) + No Wins (0) should equal 10');
        
        // Assert Account 4: 0+0 = 0
        Account acc4 = accountsByName.get('No Revenue No Wins Account');
        System.assertEquals(0, acc4.Health_Score__c, 'No Revenue (0) + No Wins (null) should equal 0');
        
        // Assert Account 5: 30+30 = 60 (edge case - exactly at threshold)
        Account acc5 = accountsByName.get('Edge Case Revenue Wins Account');
        System.assertEquals(60, acc5.Health_Score__c, 'Revenue at 250K + Wins at 25K should equal 60');
        
        // Assert Account 6: 50+50 = 100 (edge case - exactly at threshold)
        Account acc6 = accountsByName.get('Edge Case High Account');
        System.assertEquals(100, acc6.Health_Score__c, 'Revenue at 1M + Wins at 100K should equal 100');
        
        // Assert Account 7: 10+30 = 40
        Account acc7 = accountsByName.get('Low Revenue Mid Wins Account');
        System.assertEquals(40, acc7.Health_Score__c, 'Low Revenue + Mid Wins (≥25K, <100K) should equal 40');
        
        // Assert Account 8: 0+50 = 50
        Account acc8 = accountsByName.get('Null Revenue High Wins Account');
        System.assertEquals(50, acc8.Health_Score__c, 'Null Revenue + High Wins should equal 50');
    }
    
    /**
     * @description Test updateHealthScores with null input
     */
    @IsTest
    static void testUpdateHealthScores_NullInput() {
        Test.startTest();
        // Should not throw exception
        AccountHealthService.updateHealthScores(null);
        Test.stopTest();
        
        // If we get here without exception, test passes
        System.assert(true, 'Method should handle null input gracefully');
    }
    
    /**
     * @description Test updateHealthScores with empty set
     */
    @IsTest
    static void testUpdateHealthScores_EmptySet() {
        Test.startTest();
        // Should not throw exception
        AccountHealthService.updateHealthScores(new Set<Id>());
        Test.stopTest();
        
        // If we get here without exception, test passes
        System.assert(true, 'Method should handle empty set gracefully');
    }
    
    /**
     * @description Test updateHealthScores with single account
     */
    @IsTest
    static void testUpdateHealthScores_SingleAccount() {
        // Create a single account
        Account testAccount = new Account(
            Name = 'Single Test Account',
            AnnualRevenue = 750000,
            Last_90_Day_Wins__c = 50000
        );
        insert testAccount;
        
        Test.startTest();
        AccountHealthService.updateHealthScores(new Set<Id>{testAccount.Id});
        Test.stopTest();
        
        // Query updated account
        Account updatedAccount = [SELECT Health_Score__c FROM Account WHERE Id = :testAccount.Id];
        
        // Assert: 30+30 = 60
        System.assertEquals(60, updatedAccount.Health_Score__c, 
            'Mid Revenue (≥250K, <1M) + Mid Wins (≥25K, <100K) should equal 60');
    }
    
    /**
     * @description Test boundary conditions for revenue scoring
     */
    @IsTest
    static void testRevenueBoundaries() {
        List<Account> boundaryAccounts = new List<Account>{
            new Account(Name = 'Rev 249999', AnnualRevenue = 249999, Last_90_Day_Wins__c = 0),
            new Account(Name = 'Rev 250000', AnnualRevenue = 250000, Last_90_Day_Wins__c = 0),
            new Account(Name = 'Rev 999999', AnnualRevenue = 999999, Last_90_Day_Wins__c = 0),
            new Account(Name = 'Rev 1000000', AnnualRevenue = 1000000, Last_90_Day_Wins__c = 0)
        };
        insert boundaryAccounts;
        
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : boundaryAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHealthService.updateHealthScores(accountIds);
        Test.stopTest();
        
        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account acc : [SELECT Name, Health_Score__c FROM Account WHERE Id IN :accountIds]) {
            accountsByName.put(acc.Name, acc);
        }
        
        System.assertEquals(10, accountsByName.get('Rev 249999').Health_Score__c, '249,999 should score 10');
        System.assertEquals(30, accountsByName.get('Rev 250000').Health_Score__c, '250,000 should score 30');
        System.assertEquals(30, accountsByName.get('Rev 999999').Health_Score__c, '999,999 should score 30');
        System.assertEquals(50, accountsByName.get('Rev 1000000').Health_Score__c, '1,000,000 should score 50');
    }
    
    /**
     * @description Test boundary conditions for wins scoring
     */
    @IsTest
    static void testWinsBoundaries() {
        List<Account> boundaryAccounts = new List<Account>{
            new Account(Name = 'Wins 24999', AnnualRevenue = 0, Last_90_Day_Wins__c = 24999),
            new Account(Name = 'Wins 25000', AnnualRevenue = 0, Last_90_Day_Wins__c = 25000),
            new Account(Name = 'Wins 99999', AnnualRevenue = 0, Last_90_Day_Wins__c = 99999),
            new Account(Name = 'Wins 100000', AnnualRevenue = 0, Last_90_Day_Wins__c = 100000)
        };
        insert boundaryAccounts;
        
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : boundaryAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHealthService.updateHealthScores(accountIds);
        Test.stopTest();
        
        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account acc : [SELECT Name, Health_Score__c FROM Account WHERE Id IN :accountIds]) {
            accountsByName.put(acc.Name, acc);
        }
        
        System.assertEquals(10, accountsByName.get('Wins 24999').Health_Score__c, '24,999 should score 10');
        System.assertEquals(30, accountsByName.get('Wins 25000').Health_Score__c, '25,000 should score 30');
        System.assertEquals(30, accountsByName.get('Wins 99999').Health_Score__c, '99,999 should score 30');
        System.assertEquals(50, accountsByName.get('Wins 100000').Health_Score__c, '100,000 should score 50');
    }
}
