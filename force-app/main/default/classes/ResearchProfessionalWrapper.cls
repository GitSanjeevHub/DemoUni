/**
 * @author: Sush
 * @date : 20/06/2019
 * @description : Wrapper class to parse the response receive through REST API callout to Research Professional system.
 */
public class ResearchProfessionalWrapper {
	
    public class Disciplines {
		public String label;
		public Boolean focus;
	}
    
    public class Purpose {
		public String name;
	}

	public class Deadlines {
		public String deadline;
		public Boolean unconfirmed;
	}

	public class Eligibility {
		public List<String> hosts;
		public List<String> involvement;
		public List<Region> regions;
	}

	public Metadata metadata;
	public List<Records> records;

	public class Metadata {
		public Integer page;
		public Integer pageSize;
		public Integer pageCount;
		public Integer totalCount;
	}

	public class Region {
		public String name;
		public String regionCode;
	}

	public class PrimaryFunder {
		public Integer id;
		public String name;
		public Region region;
	}

	public class Records {
		public Integer id;
		public String researchProfessionalWebpage;
		public String name;
		public String bullet;
		public String description;
		public String locale;
		public String added;
		public String deadlineInfo;
		public String webpage;
		public PrimaryFunder primaryFunder;
		public List<Deadlines> deadlines;
		public List<Disciplines> disciplines;
		public List<Eligibility> eligibility;
		public List<PrimaryFunder> funders;
		public String australianFundingCategory;
        public List<Purpose> purpose;
	}

	public class Deadlines_Z {
		public Boolean unconfirmed;
	}

	
	public static ResearchProfessionalWrapper parse(String json) {
		return (ResearchProfessionalWrapper) System.JSON.deserialize(json, ResearchProfessionalWrapper.class);
    }
}