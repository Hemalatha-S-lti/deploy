import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClient, HttpClientModule } from '@angular/common/http';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './home.html',
  styleUrls: ['./home.css']
})
export class Home {
  prompt: string = '';
  isSubmitting = false;
  gptResponse: string = ''; // Store GPT answer
  submittedPrompts: string[] = [];

  constructor(private http: HttpClient) {}

  submitPrompt(): void {
    const text = this.prompt.trim();
    if (!text || this.isSubmitting) return;

    this.isSubmitting = true;
    this.gptResponse = ''; // clear previous response

    // Save the prompt locally
    this.submittedPrompts.push(text);

    // Call backend API
    this.queryGPT(text).subscribe({
      next: (res: any) => {
        this.gptResponse = res.answer; // Display GPT response
        this.prompt = ''; // clear input
        this.isSubmitting = false;
      },
      error: (err) => {
        console.error(err);
        this.gptResponse = 'Error fetching response';
        this.isSubmitting = false;
      }
    });
  }

  clearPrompt(): void {
    if (this.isSubmitting) return;
    this.prompt = '';
    this.gptResponse = '';
  }

  get isSubmitDisabled(): boolean {
    return !((this.prompt ?? '').trim()) || this.isSubmitting;
  }

  queryGPT(prompt: string): Observable<any> {
    return this.http.post('http://localhost:3000/api/query', { prompt });
  }
}

<div class="home-center dark-theme" style="--header-h: 0px;">
  <section class="prompt-card" role="region" aria-labelledby="promptTitle">
    <h2 class="title" id="promptTitle">Ask anything</h2>

    <label class="sr-only" for="promptInput">Your prompt</label>
    <textarea
      id="promptInput"
      class="prompt-input"
      [(ngModel)]="prompt"
      placeholder="Type your prompt here…"
      (keydown.control.enter)="submitPrompt()"
      (keydown.meta.enter)="submitPrompt()"
    ></textarea>

    <div class="actions">
      <button class="clear-btn" type="button" (click)="clearPrompt()" [disabled]="!prompt.length || isSubmitting">
        Clear
      </button>

      <button class="primary-btn" type="button" (click)="submitPrompt()" [disabled]="isSubmitDisabled">
        {{ isSubmitting ? 'Submitting…' : 'Submit' }}
      </button>
    </div>

    <!-- Submitted prompts displayed below -->
    <div class="submitted-prompts" *ngIf="submittedPrompts.length">
      <h3 class="submitted-title">Submitted Prompts:</h3>
      <div class="prompt-card-small" *ngFor="let p of submittedPrompts">
        {{ p }}
      </div>
    </div>

    <!-- GPT Response Display -->
    <div class="gpt-response" *ngIf="gptResponse">
      <h3>GPT Response:</h3>
      <div class="response-card">
        {{ gptResponse }}
      </div>
    </div>
  </section>
</div>
