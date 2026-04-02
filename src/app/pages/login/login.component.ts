import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  email = '';
  password = '';
  error = '';

  constructor(
    public readonly auth: AuthService,
    private readonly router: Router
  ) {}

  submit(): void {
    this.error = '';

    this.auth.login(this.email.trim(), this.password).subscribe({
      next: (response) => {
        this.auth.applyLogin(response);
        this.router.navigateByUrl(this.auth.defaultRoute());
      },
      error: (error) => {
        this.error = error?.error?.message || 'Login failed. Please check your email and password.';
      }
    });
  }
}
