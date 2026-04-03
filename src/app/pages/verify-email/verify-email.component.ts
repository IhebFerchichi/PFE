import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-verify-email',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './verify-email.component.html',
  styleUrl: './verify-email.component.scss'
})
export class VerifyEmailComponent {
  email = '';
  token = '';
  info = 'Check your inbox for the verification email.';
  error = '';
  verified = false;
  private tokenHandled = false;

  constructor(
    public readonly auth: AuthService,
    private readonly route: ActivatedRoute,
    private readonly router: Router
  ) {
    this.route.queryParamMap.subscribe((params) => {
      this.email = params.get('email') ?? this.email;
      this.token = params.get('token') ?? this.token;
      this.info = params.get('message') ?? this.info;

      if (this.token && !this.tokenHandled) {
        this.tokenHandled = true;
        this.submitVerification();
      }
    });
  }

  submitVerification(): void {
    if (!this.token.trim()) {
      this.error = 'Verification token is missing.';
      return;
    }

    this.error = '';
    this.auth.verifyEmail(this.token.trim()).subscribe({
      next: (response) => {
        this.verified = true;
        this.info = response.message;
      },
      error: (error) => {
        this.error = error?.error?.message || 'Could not verify this email link.';
      }
    });
  }

  resend(): void {
    if (!this.email.trim()) {
      this.error = 'Enter your email so we can resend the verification link.';
      return;
    }

    this.error = '';
    this.auth.resendVerification(this.email.trim()).subscribe({
      next: (response) => {
        this.info = response.message;
      },
      error: (error) => {
        this.error = error?.error?.message || 'Could not resend the verification email.';
      }
    });
  }

  goToLogin(): void {
    this.router.navigate(['/login'], {
      queryParams: {
        email: this.email,
        message: this.info || 'Email verified successfully. You can sign in now.'
      }
    });
  }
}
