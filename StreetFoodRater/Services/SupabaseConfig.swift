//
//  SupabaseConfig.swift
//  StreetFoodRater
//
//  Created by GPT on 16/10/2025.
//
//  Kid-Friendly Explanation:
//  This file holds the "keys" to access your Supabase cloud database.
//  Think of it like storing your house address and door code so the app knows
//  where to send and get data from the cloud!
//

import Foundation

/// Stores the Supabase project credentials
enum SupabaseConfig {
    /// Your Supabase project URL - like the address of your cloud storage
    static let projectURL = "https://rmadxcfuromkaihemxth.supabase.co"
    
    /// Your Supabase anon/public key - like a safe password that lets the app talk to the cloud
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtYWR4Y2Z1cm9ta2FpaGVteHRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1OTkzNzUsImV4cCI6MjA3NjE3NTM3NX0.vKxBE_PR3hduHcdo44nkkO5lsuKgZDer5KVwTRboHFg"
}

