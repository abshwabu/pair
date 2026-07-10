<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateGoalRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'category' => ['required', 'string', Rule::in(['read', 'watch', 'fitness', 'habit', 'custom'])],
            'title' => ['required', 'string', 'max:255'],
            'target_description' => ['required', 'string'],
            'pace' => ['required', 'string', Rule::in(['relaxed', 'steady', 'intense'])],
        ];
    }
}
