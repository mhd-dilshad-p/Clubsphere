import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabase = SupabaseClient('https://pdynhfwjmpdtcdlpjrbp.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBkeW5oZndqbXBkdGNkbHBqcmJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MzMxNDMsImV4cCI6MjA5NjMwOTE0M30.yDhOORhIk7IwlBu0EE_wsj9Xgdnt7KxE2-Z6-crTilE');
  
  final res = await supabase.from('clubs').select('location');
  print(res);
}
