/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout implements Queueable, Database.AllowsCallouts {
	private String dummyUserId;

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	public DummyJSONCallout(String dummyUserId) {
		this.dummyUserId = dummyUserId;

	}
	
	public void execute(QueueableContext qc) {
		getDummyJSONUserFromId(dummyUserId);
	}

	public static void getDummyJSONUserFromId(String dummyUserId) {
		// Create HTTP request to send.
		HttpRequest req = new HttpRequest();
		req.setEndpoint('callout:DummyJSONUser/users/' + dummyUserId);
		req.setMethod('GET');

		try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                String resBody = res.getBody();
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(resBody);
                System.debug('Response Body: ' + resBody);
                
                Contact cont = new Contact();
                cont.DummyJSON_Id__c = dummyUserId;
                cont.FirstName = (String) jsonResponse.get('firstName');
                cont.LastName = (String) jsonResponse.get('lastName');
                cont.Email = (String) jsonResponse.get('email');
				cont.Phone = (String) jsonResponse.get('phone');

				Map<String, Object> address = (Map<String, Object>) jsonResponse.get('address');
				if (address !=null) {
					cont.MailingCity = (String) address.get('city');
					cont.MailingPostalCode = (String) address.get('postalCode');
					cont.MailingStreet = (String) address.get('address');
					cont.MailingCountry = (String) address.get('country');
					cont.MailingState = (String) address.get('state');
				}
				String bdateString = (String) jsonResponse.get('birthDate');
				if (bdateString != null) {
					cont.Birthdate = Date.valueOf(bdateString);
				}
                
                upsert cont DummyJSON_Id__c; 
            } else {
                System.debug('HTTP callout failed: Status Code = ' + res.getStatusCode());
            }
        } 
		
		catch (Exception e) {
            System.debug('Exception during HTTP callout: ' + e.getMessage());
			throw e;
        }
	}
	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {
		Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
		
		Contact cont = new Contact();

		Object jsonId = jsonMap.get('id');
		if (jsonId != null) {
			cont.DummyJSON_Id__c = jsonId.toString();
		}

		cont.FirstName = (String) jsonMap.get('firstName');
		cont.LastName = (String) jsonMap.get('lastName');
		cont.Email = (String) jsonMap.get('email');
		cont.Phone = (String) jsonMap.get('phone');

		Map<String, Object> address = (Map<String, Object>) jsonMap.get('address');
		if (address !=null) {
			cont.MailingCity = (String) address.get('city');
			cont.MailingPostalCode = (String) address.get('postalCode');
			cont.MailingStreet = (String) address.get('address');
			cont.MailingCountry = (String) address.get('country');
			cont.MailingState = (String) address.get('state');
		}
		String bdateString = (String) jsonMap.get('birthDate');
		if (bdateString != null) {
			cont.Birthdate = Date.valueOf(bdateString);
		}

		return cont;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	public static void postCreateDummyJSONUser(String contactId) {
		HttpRequest req = new HttpRequest();
		Http http = new Http();

		req.setEndpoint('callout:DummyJSONUser/users/add');
		req.setMethod('POST');
		req.setBody(generateDummyJsonUserPayload(contactId));
		
		HttpResponse res = http.send(req);

		if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
			Contact conToUpadate = [SELECT Id, DummyJSON_Last_Updated__c FROM Contact WHERE Id = :contactId LIMIT 1];
			conToUpadate.DummyJSON_Last_Updated__c = System.now();
			update conToUpadate;

		}

	}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {
		Contact dummyContact = [SELECT Id, FirstName, LastName, Email, Phone FROM Contact WHERE Id =: contactId];
		Map<String, String> mapOfDummyContact = new Map<String, String>();
		
		mapOfDummyContact.put('salesforceId', dummyContact.Id != null ? dummyContact.Id : 'unknown');
		mapOfDummyContact.put('firstName', dummyContact.FirstName != null ? dummyContact.FirstName : 'unknown');
		mapOfDummyContact.put('lastName', dummyContact.LastName != null ? dummyContact.LastName : 'unknown');
		mapOfDummyContact.put('email', dummyContact.Email != null ? dummyContact.Email : 'unknown');
		mapOfDummyContact.put('phone', dummyContact.Phone != null ? dummyContact.Phone : 'unknown');

		String jsonStringFromMap = JSON.serialize(mapOfDummyContact);

		return jsonStringFromMap;
	}
}