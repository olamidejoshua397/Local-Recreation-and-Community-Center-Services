# Local Recreation and Community Center Services

A comprehensive smart contract system built on Stacks blockchain using Clarity for managing local recreation and community center operations.

## System Overview

This system provides a complete solution for managing recreation center services including:

- **Membership Management**: Track member status, renewals, and benefits
- **Facility Reservations**: Book courts, rooms, and recreational spaces
- **Equipment Rental**: Manage sports equipment and facility gear
- **Program Enrollment**: Register for classes, activities, and events
- **Event Coordination**: Organize community events and activities
- **Volunteer Management**: Coordinate volunteer opportunities and tracking

## Smart Contracts

### 1. Membership Contract (`membership.clar`)
- Member registration and profile management
- Membership tier system (Basic, Premium, Family)
- Automatic renewal and payment tracking
- Member benefits and access control

### 2. Facility Reservation Contract (`facility-reservations.clar`)
- Real-time facility availability checking
- Booking system with time slot management
- Cancellation and modification policies
- Pricing based on facility type and member status

### 3. Equipment Rental Contract (`equipment-rental.clar`)
- Equipment inventory management
- Rental duration and pricing system
- Damage reporting and security deposits
- Equipment maintenance scheduling

### 4. Programs Contract (`programs-events.clar`)
- Class and program scheduling
- Enrollment capacity management
- Instructor assignment and payment
- Event coordination and ticketing

### 5. Volunteer Management Contract (`volunteer-management.clar`)
- Volunteer registration and background checks
- Opportunity posting and assignment
- Hour tracking and recognition system
- Community service coordination

## Key Features

- **Transparent Pricing**: All fees and costs are clearly defined in smart contracts
- **Automated Operations**: Reduce manual overhead with blockchain automation
- **Member Benefits**: Tiered membership system with progressive benefits
- **Community Focus**: Support for youth programs and senior activities
- **Accountability**: Immutable records of all transactions and activities

## Technical Architecture

- **Blockchain**: Stacks blockchain
- **Smart Contract Language**: Clarity
- **Testing Framework**: Vitest
- **Configuration**: Clarinet for local development

## Getting Started

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite
5. Deploy contracts using `clarinet deploy`

## Contract Interactions

All contracts are designed to work independently without cross-contract calls, ensuring maximum security and simplicity. Each contract maintains its own state and can be upgraded independently.

## Security Considerations

- Input validation on all public functions
- Access control for administrative functions
- Proper error handling and assertions
- No external dependencies or trait usage

## License

MIT License - See LICENSE file for details
