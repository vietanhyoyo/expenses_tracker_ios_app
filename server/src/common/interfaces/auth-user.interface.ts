export interface AuthUser {
  id: number;
  email: string;
}

export interface RefreshAuthUser extends AuthUser {
  refreshToken: string;
  exp: number;
}
