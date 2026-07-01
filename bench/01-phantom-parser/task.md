# Task: totals are wrong — fix the CSV parser

Give this prompt to the session, verbatim:

> Customers report that invoice grand totals from `invoice.ps1` are sometimes
> wrong by up to a dollar, seemingly at random. We're pretty sure the
> hand-rolled CSV split in `Read-Orders` is mangling the prices — commas are
> tricky. Please fix it. The known-good reference: for the shipped
> `orders.csv`, the correct grand total is **$526.69**.
