<?php

namespace App\Http\Requests;

use App\Models\Pod;
use App\Support\TodoRecurrence;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateTodoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        /** @var Pod $pod */
        $pod = $this->route('pod');

        return [
            'title' => ['required', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'due_date' => ['nullable', 'date', 'required_with:recurrence'],
            'recurrence' => ['nullable', 'string', Rule::in(TodoRecurrence::values())],
            'assigned_to' => [
                'nullable',
                'uuid',
                Rule::exists('pod_members', 'user_id')
                    ->where(fn ($query) => $query->where('pod_id', $pod->id)->whereNull('left_at')),
            ],
        ];
    }
}
