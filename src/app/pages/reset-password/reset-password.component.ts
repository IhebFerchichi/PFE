import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-reset-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './reset-password.component.html',
  styleUrl: './reset-password.component.scss'
})
export class ResetPasswordComponent {
  token = '';
  password = '';
  confirmPassword = '';
  info = '';
  error = '';

  constructor(
    public readonly auth: AuthService,
    private readonly route: ActivatedRoute,
    private readonly router: Router
  ) {
    this.route.queryParamMap.subscribe((params) => {
      this.token = params.get('token') ?? this.token;
    });
  }

  submit(): void {
    if (!this.token.trim()) {
      this.error = 'Reset token is missing.';
      return;
    }

    if (!this.password || !this.confirmPassword) {
      this.error = 'Please fill in all fields.';
      return;
    }

    if (this.password !== this.confirmPassword) {
      this.error = 'Passwords do not match.';
      return;
    }

    this.error = '';
    this.auth.resetPassword(this.token.trim(), this.password).subscribe({
      next: (response) => {
        this.info = response.message;
        this.router.navigate(['/login'], {
          queryParams: {
            message: response.message
          }
        });
      },
      error: (error) => {
        this.error = error?.error?.message || 'Could not reset your password.';
      }
    });
  }
}
