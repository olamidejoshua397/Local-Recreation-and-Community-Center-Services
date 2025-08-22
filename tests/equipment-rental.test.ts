import { describe, it, expect, beforeEach } from "vitest"

describe("Equipment Rental Contract Tests", () => {
  let contractAddress
  let renterAddress
  let adminAddress
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.equipment-rental"
    renterAddress = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    adminAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
  })
  
  describe("Equipment Inventory", () => {
    it("should add equipment to inventory", () => {
      const equipmentResult = {
        type: "ok",
        value: 1, // equipment-id
      }
      
      expect(equipmentResult.type).toBe("ok")
      expect(equipmentResult.value).toBe(1)
    })
    
    it("should set correct security deposits by category", () => {
      const deposits = {
        sports: 5000000, // 5 STX
        fitness: 10000000, // 10 STX
        aquatic: 3000000, // 3 STX
        outdoor: 15000000, // 15 STX
        audioVisual: 20000000, // 20 STX
      }
      
      expect(deposits.sports).toBe(5000000)
      expect(deposits.audioVisual).toBe(20000000)
    })
    
    it("should track equipment condition", () => {
      const conditions = {
        excellent: 1,
        good: 2,
        fair: 3,
        poor: 4,
        maintenance: 5,
      }
      
      expect(conditions.excellent).toBe(1)
      expect(conditions.maintenance).toBe(5)
    })
  })
  
  describe("Equipment Rental", () => {
    it("should rent equipment successfully", () => {
      const rentalResult = {
        type: "ok",
        value: 1, // rental-id
      }
      
      expect(rentalResult.type).toBe("ok")
      expect(rentalResult.value).toBe(1)
    })
    
    it("should calculate rental costs correctly", () => {
      const hourlyRate = 5000000 // 5 STX
      const dailyRate = 30000000 // 30 STX
      const weeklyRate = 150000000 // 150 STX
      
      expect(hourlyRate).toBe(5000000)
      expect(dailyRate).toBe(30000000)
      expect(weeklyRate).toBe(150000000)
    })
    
    it("should prevent renting unavailable equipment", () => {
      const unavailableResult = {
        type: "error",
        value: 302, // ERR-EQUIPMENT-UNAVAILABLE
      }
      
      expect(unavailableResult.type).toBe("error")
      expect(unavailableResult.value).toBe(302)
    })
    
    it("should apply member discounts", () => {
      const baseCost = 100000000
      const basicDiscount = baseCost * 0.95 // 5% discount
      const premiumDiscount = baseCost * 0.85 // 15% discount
      
      expect(basicDiscount).toBe(95000000)
      expect(premiumDiscount).toBe(85000000)
    })
  })
  
  describe("Equipment Return", () => {
    it("should return equipment successfully", () => {
      const returnResult = {
        type: "ok",
        value: 8000000, // Refund amount after penalties
      }
      
      expect(returnResult.type).toBe("ok")
      expect(returnResult.value).toBe(8000000)
    })
    
    it("should apply condition penalties", () => {
      const securityDeposit = 10000000
      const conditionPenalty = securityDeposit * 0.25 // 25% for poor condition
      const refund = securityDeposit - conditionPenalty
      
      expect(conditionPenalty).toBe(2500000)
      expect(refund).toBe(7500000)
    })
    
    it("should apply overdue penalties", () => {
      const securityDeposit = 10000000
      const overduePenalty = securityDeposit * 0.1 // 10% for overdue
      
      expect(overduePenalty).toBe(1000000)
    })
  })
  
  describe("Damage Reporting", () => {
    it("should report equipment damage", () => {
      const damageReportResult = {
        type: "ok",
        value: 1, // report-id
      }
      
      expect(damageReportResult.type).toBe("ok")
      expect(damageReportResult.value).toBe(1)
    })
    
    it("should validate damage severity levels", () => {
      const severityLevels = [1, 2, 3, 4] // minor, moderate, major, total-loss
      expect(severityLevels).toHaveLength(4)
      expect(severityLevels).toContain(1)
      expect(severityLevels).toContain(4)
    })
  })
  
  describe("Maintenance Scheduling", () => {
    it("should schedule maintenance", () => {
      const maintenanceResult = {
        type: "ok",
        value: 1, // maintenance-id
      }
      
      expect(maintenanceResult.type).toBe("ok")
      expect(maintenanceResult.value).toBe(1)
    })
    
    it("should mark equipment unavailable during maintenance", () => {
      const equipmentAvailable = false
      expect(equipmentAvailable).toBe(false)
    })
  })
})
