import type { Greeting } from '../entities/greeting';

/**
 * API response for GET /api/greetings
 */
export interface GetGreetingsResponse {
  status: 'success';
  data: Greeting[];
}
