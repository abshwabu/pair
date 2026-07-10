<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateGoalRequest extends FormRequest
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
            'category' => ['sometimes', 'required', 'string', Rule::in(['read', 'watch', 'fitness', 'habit', 'custom'])],
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'target_description' => ['sometimes', 'required', 'string'],
            'pace' => ['sometimes', 'required', 'string', Rule::in(['relaxed', 'steady', 'intense'])],
        ];
    }
}
