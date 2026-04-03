import { Routes } from '@angular/router';
import { adminGuard, authGuard } from './core/auth.guard';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PacksComponent } from './pages/packs/packs.component';
import { AlertsComponent } from './pages/alerts/alerts.component';
import { LoginComponent } from './pages/login/login.component';
import { SignupComponent } from './pages/signup/signup.component';
import { VerifyEmailComponent } from './pages/verify-email/verify-email.component';
import { ForgotPasswordComponent } from './pages/forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './pages/reset-password/reset-password.component';
import { RequestsComponent } from './pages/requests/requests.component';
import { AdminRequestsComponent } from './pages/admin-requests/admin-requests.component';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'signup', component: SignupComponent },
  { path: 'verify-email', component: VerifyEmailComponent },
  { path: 'forgot-password', component: ForgotPasswordComponent },
  { path: 'reset-password', component: ResetPasswordComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [adminGuard] },
  { path: 'packs', component: PacksComponent, canActivate: [authGuard] },
  { path: 'alerts', component: AlertsComponent, canActivate: [authGuard] },
  { path: 'requests', component: RequestsComponent, canActivate: [authGuard] },
  { path: 'admin/requests', component: AdminRequestsComponent, canActivate: [adminGuard] },
  { path: '**', redirectTo: 'login' }
];
