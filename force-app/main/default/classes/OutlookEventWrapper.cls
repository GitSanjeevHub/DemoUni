public class OutlookEventWrapper {
    
    public Class Status { 
        public String response;
        public String x_time;
    }

    public String x_odata_context;
    public String x_odata_etag;
    public String id; // Store this against the task object in Salesforce
    public String iCalUid;
    public String subject;
    public String isCancelled = 'false';
    public String isOrganizer = 'false';
    public String showAs = 'tentative';
    public List<String> categories = new List<String>();
    public String bodyPreview; 
    public Body body;
    public DateTimeWrapper start;
    public DateTimeWrapper x_end;
    //public Location location = new Location();
    //public List<Locations> locations = new List<Locations>();
    public List<Attendee> attendees = new List<Attendee>();
    public Organizer organizer;

    public class Address {
        public String street;
        public String city;
        public String state;
        public String coutryOrRegion;
        public String postalCode;
    }

    public class Organizer {
        public EmailAddress emailAddress;
    }

    public class DateTimeWrapper {
        public String x_dateTime;
        public String timeZone;

        public DateTimeWrapper(String x_dateTime, String timeZone){
            this.x_dateTime = x_dateTime;
            this.timeZone = timeZone;
        }
    }

    public class Coordinates {
        public Double latitude;
        public Double longitude;
    }

    public class Locations { 
        public String displayName;
        public String locationType;
        public String uniqueIdType;
        public String uniqueId;
        public Address address;
        public Coordinates coordinates;
    }

    public class Attendee { 
        public String type;
        //public String status;
        public EmailAddress emailAddress;
    }

    public class Body {
        public String contentType;
        public String content;
    }

    public class EmailAddress {
        public String name;
        public String address;
    }

    public class Location {
        public String displayName;
        public String locationType;
        public String uniqueId;
        public String uniqueIdType;
    }

}