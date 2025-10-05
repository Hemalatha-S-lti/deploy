import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './home.html',
  styleUrls: ['./home.css']
})
export class Home {
  prompt: string = '';
  isSubmitting = false;

  // Array to store submitted prompts and GPT responses
  submittedPrompts: string[] = [];

  // Submit prompt to backend
  submitPrompt(): void {
    const text = this.prompt.trim();
    if (!text || this.isSubmitting) return;

    this.isSubmitting = true;

    fetch("http://localhost:5000/api/query", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: text })
    })
      .then(res => res.json())
      .then(data => {
        console.log("Backend response:", data); // Debugging

        // Safely get GPT response
        const gptResponse = data.response ?? data.error ?? "No response from GPT";

        // Store question + GPT response
        this.submittedPrompts.push(`Q: ${text}\nA: ${gptResponse}`);
        this.prompt = '';
        this.isSubmitting = false;
      })
      .catch(err => {
        console.error("Error fetching response:", err);
        this.submittedPrompts.push(`Q: ${text}\nA: Error fetching response`);
        this.isSubmitting = false;
      });
  }

  // Clear the prompt textarea
  clearPrompt(): void {
    if (this.isSubmitting) return;
    this.prompt = '';
  }

  // Disable submit button if no text or submitting
  get isSubmitDisabled(): boolean {
    return !((this.prompt ?? '').trim()) || this.isSubmitting;
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
        <pre>{{ p }}</pre>
      </div>
    </div>
  </section>
</div>
