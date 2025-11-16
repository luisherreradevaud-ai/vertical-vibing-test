import type { Company, CompanyMember, CompanyRole, CompanyWithMembers } from '../entities/company';

/**
 * Create Company DTO
 */
export interface CreateCompanyDTO {
  name: string;
  slug: string;
}

/**
 * Update Company DTO
 */
export interface UpdateCompanyDTO {
  name?: string;
  slug?: string;
}

/**
 * Add Company Member DTO
 */
export interface AddCompanyMemberDTO {
  email: string;
  role: CompanyRole;
}

/**
 * Update Company Member DTO
 */
export interface UpdateCompanyMemberDTO {
  role: CompanyRole;
}

/**
 * Company Response
 */
export interface CompanyResponse {
  status: 'success';
  data: {
    company: Company;
  };
}

/**
 * Company with Members Response
 */
export interface CompanyWithMembersResponse {
  status: 'success';
  data: {
    company: CompanyWithMembers;
  };
}

/**
 * Companies List Response
 */
export interface CompaniesListResponse {
  status: 'success';
  data: {
    companies: Company[];
  };
}

/**
 * Company Members List Response
 */
export interface CompanyMembersListResponse {
  status: 'success';
  data: {
    members: Array<CompanyMember & {
      user: {
        id: string;
        email: string;
        name: string | null;
      };
    }>;
  };
}

/**
 * Company Member Response
 */
export interface CompanyMemberResponse {
  status: 'success';
  data: {
    member: CompanyMember;
  };
}
