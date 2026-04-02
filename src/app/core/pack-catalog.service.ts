import { Injectable, computed, signal } from '@angular/core';
import { ApiService, VisiblePack } from './api.service';

@Injectable({ providedIn: 'root' })
export class PackCatalogService {
  private readonly selectedPackCodeKey = 'bp.selected-pack-code';

  readonly packs = signal<VisiblePack[]>([]);
  readonly loading = signal(false);
  readonly selectedPackCode = signal<string | null>(localStorage.getItem(this.selectedPackCodeKey));
  readonly selectedPack = computed(
    () => this.packs().find((pack) => pack.packageCode === this.selectedPackCode()) ?? this.packs()[0] ?? null
  );

  constructor(private readonly api: ApiService) {}

  loadPacks(): void {
    this.loading.set(true);

    this.api.getVisiblePacks().subscribe({
      next: (packs) => {
        this.packs.set(Array.isArray(packs) ? packs : []);
        this.ensureValidSelection();
        this.loading.set(false);
      },
      error: (error) => {
        console.error('getVisiblePacks failed', error);
        this.packs.set([]);
        this.selectedPackCode.set(null);
        localStorage.removeItem(this.selectedPackCodeKey);
        this.loading.set(false);
      }
    });
  }

  setSelectedPack(packageCode: string): void {
    this.selectedPackCode.set(packageCode);
    localStorage.setItem(this.selectedPackCodeKey, packageCode);
  }

  refreshSelection(): void {
    this.ensureValidSelection();
  }

  private ensureValidSelection(): void {
    const packs = this.packs();
    const currentCode = this.selectedPackCode();

    if (!packs.length) {
      this.selectedPackCode.set(null);
      localStorage.removeItem(this.selectedPackCodeKey);
      return;
    }

    if (currentCode && packs.some((pack) => pack.packageCode === currentCode)) {
      return;
    }

    this.setSelectedPack(packs[0].packageCode);
  }
}
