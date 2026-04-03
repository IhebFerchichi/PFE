import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-forgot-password',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.scss'
})
export class ForgotPasswordComponent {
  email = '';
  info = '';
  error = '';

  constructor(public readonly auth: AuthService) {}

  submit(): void {
    if (!this.email.trim()) {
      this.error = 'Email is required.';
      return;
    }

    this.error = '';
    this.auth.requestPasswordReset(this.email.trim()).subscribe({
      next: (response) => {
        this.info = response.message;
      },
      error: (error) => {
        this.error = error?.error?.message || 'Could not send a reset email.';
      }
    });
  }
}
