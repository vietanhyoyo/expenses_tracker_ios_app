export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

export interface PublicAuthUser {
  id: number;
  email: string;
  createdAt: Date;
}

export interface AuthResult extends TokenPair {
  user: PublicAuthUser;
}
