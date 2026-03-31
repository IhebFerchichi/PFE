import { Routes } from '@angular/router';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PacksComponent } from './pages/packs/packs.component';
import { AlertsComponent } from './pages/alerts/alerts.component';

export const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'packs', component: PacksComponent },
  { path: 'alerts', component: AlertsComponent },
  { path: '**', redirectTo: 'dashboard' }
];