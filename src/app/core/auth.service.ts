import { Injectable, signal } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { finalize } from 'rxjs';

export type UserRole = 'ADMIN' | 'USER';

export type AuthUser = {
  id: number;
  email: string;
  fullName: string;
  role: UserRole;
  emailVerified: boolean;
};

type LoginResponse = AuthUser & {
  token: string;
  userId: number;
};

type AuthMessageResponse = {
  message: string;
  email: string;
};

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly baseUrl = 'http://localhost:8080';
  private readonly tokenKey = 'bp.token';
  private readonly userKey = 'bp.user';

  readonly user = signal<AuthUser | null>(this.readStoredUser());
  readonly token = signal<string | null>(this.readStoredToken());
  readonly loading = signal(false);

  constructor(
    private readonly http: HttpClient,
    private readonly router: Router
  ) {}

  login(email: string, password: string) {
    this.loading.set(true);

    return this.http.post<LoginResponse>(`${this.baseUrl}/auth/login`, { email, password }).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  register(fullName: string, email: string, password: string) {
    this.loading.set(true);

    return this.http.post<AuthMessageResponse>(`${this.baseUrl}/auth/register`, { fullName, email, password }).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  verifyEmail(token: string) {
    this.loading.set(true);

    return this.http.post<AuthMessageResponse>(`${this.baseUrl}/auth/verify-email`, { token }).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  resendVerification(email: string) {
    this.loading.set(true);

    return this.http.post<AuthMessageResponse>(`${this.baseUrl}/auth/resend-verification`, { email }).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  requestPasswordReset(email: string) {
    this.loading.set(true);

    return this.http.post<AuthMessageResponse>(`${this.baseUrl}/auth/forgot-password`, { email }).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  resetPassword(token: string, password: string) {
    this.loading.set(true);

    return this.http.post<AuthMessageResponse>(`${this.baseUrl}/auth/reset-password`, { token, password }).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  fetchMe() {
    this.loading.set(true);

    return this.http.get<AuthUser>(`${this.baseUrl}/auth/me`).pipe(
      finalize(() => this.loading.set(false))
    );
  }

  applyLogin(response: LoginResponse): void {
    const user: AuthUser = {
      id: response.userId,
      email: response.email,
      fullName: response.fullName,
      role: response.role,
      emailVerified: response.emailVerified
    };

    this.token.set(response.token);
    this.user.set(user);
    localStorage.setItem(this.tokenKey, response.token);
    localStorage.setItem(this.userKey, JSON.stringify(user));
  }

  restoreSession(): void {
    const token = this.readStoredToken();
    const user = this.readStoredUser();

    if (!token || !user) {
      return;
    }

    this.token.set(token);
    this.user.set(user);

    this.fetchMe().subscribe({
      next: (me) => {
        this.user.set(me);
        localStorage.setItem(this.userKey, JSON.stringify(me));
      },
      error: () => this.logout(false)
    });
  }

  logout(navigate = true): void {
    this.token.set(null);
    this.user.set(null);
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);

    if (navigate) {
      this.router.navigateByUrl('/login');
    }
  }

  isAuthenticated(): boolean {
    return Boolean(this.token());
  }

  isAdmin(): boolean {
    return this.user()?.role === 'ADMIN';
  }

  defaultRoute(): string {
    return this.isAdmin() ? '/dashboard' : '/packs';
  }

  private readStoredToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  private readStoredUser(): AuthUser | null {
    const raw = localStorage.getItem(this.userKey);
    if (!raw) {
      return null;
    }

    try {
      return JSON.parse(raw) as AuthUser;
    } catch {
      localStorage.removeItem(this.userKey);
      return null;
    }
  }
}
