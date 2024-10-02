public with sharing class ContactTriggerHandler extends TriggerHandler {
    
    @TestVisible
    protected virtual override void beforeInsert() {
        List<Contact> newContacts = (List<Contact>) Trigger.new;
        
        for (Contact con : newContacts) {
            if (con.DummyJSON_Id__c == null) {
                con.DummyJSON_Id__c = String.valueOf(Math.round(Math.random() * 100));
            }
        }
    }

    @TestVisible
    protected virtual override void afterInsert() {
        List<Contact> newContacts = (List<Contact>) Trigger.new;
    
        for (Contact con : newContacts) {
            if (Integer.valueOf(con.DummyJSON_Id__c) <=100) {
                System.enqueueJob(new DummyJSONCallout(con.DummyJSON_Id__c));
            }
        } 
    }
}    