// Extract attendance data from the SAP WebDynpro portal using JS
async function extractAttendance(year, session) {
  "use strict";
  
  // Helper to wait
  const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
  
  // Find the frame containing the Web Dynpro app
  function findWebDynproDocument() {
    function searchWin(win) {
      try {
        if (win.document && win.document.forms && win.document.forms['sap.client.SsrClient.form']) {
          return win.document;
        }
        for (let i = 0; i < win.frames.length; i++) {
          const doc = searchWin(win.frames[i]);
          if (doc) return doc;
        }
      } catch (e) {}
      return null;
    }
    return searchWin(window) || document;
  }
  
  const targetDoc = findWebDynproDocument();
  
  // Helper to find node by xpath
  function xpath(expression, contextNode = targetDoc) {
    const result = targetDoc.evaluate(
      expression,
      contextNode,
      null,
      XPathResult.FIRST_ORDERED_NODE_TYPE,
      null
    );
    return result.singleNodeValue;
  }
  
  // Wait for the form to be ready
  async function waitForForm() {
    for (let i = 0; i < 50; i++) {
      const yearLabel = xpath('//label[contains(normalize-space(.), "Year")]');
      const sessionLabel = xpath('//label[contains(normalize-space(.), "Session")]');
      let submitBtn = xpath('//div[contains(@class, "lsButton")]//span[contains(text(), "Submit")]');
      if (!submitBtn) submitBtn = xpath('//div[contains(@class, "urBtn") and contains(., "Submit")]');
      if (!submitBtn) submitBtn = xpath('//span[contains(text(), "Submit") and not(*)]');
      if (!submitBtn) submitBtn = xpath('//div[contains(text(), "Submit") and not(*)]');
      if (!submitBtn) submitBtn = xpath('//a[contains(text(), "Submit") or contains(@title, "Submit")]');
      if (!submitBtn) submitBtn = xpath('//input[@value="Submit" or @title="Submit"]');
      if (!submitBtn) submitBtn = xpath('//*[contains(text(), "Submit") and not(*)]');
      
      if (i % 10 === 0) {
          console.log(`[JS Debug] Attempt ${i}: YearLabel=${!!yearLabel}, SessionLabel=${!!sessionLabel}, SubmitBtn=${!!submitBtn}`);
      }

      if (yearLabel && sessionLabel && submitBtn) return true;
      await wait(100);
    }
    return false;
  }
  
  if (!(await waitForForm())) {
    return { success: false, error: "Could not find form elements", data: null };
  }
  
  // Helper to select a WebDynpro dropdown
  async function selectDropdown(labelText, targetValue) {
    const label = xpath(`//label[contains(normalize-space(.), "${labelText}")]`);
    if (!label) throw new Error(`Label ${labelText} not found`);
    
    const row = label.closest("tr");
    if (!row) throw new Error(`Row for ${labelText} not found`);
    
    const arrow = row.querySelector("span.lsField__help");
    if (!arrow) throw new Error(`Dropdown arrow for ${labelText} not found`);
    
    // Open dropdown
    arrow.scrollIntoView({ block: "center", behavior: "smooth" });
    arrow.click();
    
    // Wait for the popup listbox
    let popup = null;
    for (let i = 0; i < 30; i++) {
      const popups = targetDoc.querySelectorAll(".lsListbox--popup");
      for (const p of popups) {
        if (p.offsetParent !== null) {
          popup = p;
          break;
        }
      }
      if (popup) break;
      await wait(100);
    }
    
    if (!popup) throw new Error(`Dropdown popup for ${labelText} didn't open`);
    
    // Find and click the option
    const options = Array.from(popup.querySelectorAll(".lsListbox__value"))
                         .filter((opt) => opt.offsetParent !== null);
    
    const targetLower = targetValue.trim().toLowerCase();
    let found = false;
    
    for (const opt of options) {
      const text = opt.innerText.trim().toLowerCase();
      const val = (opt.getAttribute("data-itemvalue1") || "").toLowerCase();
      if (text === targetLower || text.includes(targetLower) || val === targetLower || val.includes(targetLower)) {
        found = true;
        opt.scrollIntoView({ block: "center", behavior: "smooth" });
        opt.dispatchEvent(new MouseEvent("mouseover", { bubbles: true }));
        opt.click();
        await wait(100);
        break;
      }
    }
    
    if (!found) throw new Error(`Option ${targetValue} not found in ${labelText}`);
  }
  
  try {
    await selectDropdown("Year", year);
    await wait(2500);
    await selectDropdown("Session", session);
    await wait(2500);
  } catch (e) {
    return { success: false, error: e.message, data: null };
  }
  
  // Click submit
  let submitBtn = xpath('//div[contains(@class, "lsButton")]//span[contains(text(), "Submit")]');
  if (!submitBtn) submitBtn = xpath('//div[contains(@class, "urBtn") and contains(., "Submit")]');
  if (!submitBtn) submitBtn = xpath('//span[contains(text(), "Submit") and not(*)]');
  if (!submitBtn) submitBtn = xpath('//div[contains(text(), "Submit") and not(*)]');
  if (!submitBtn) submitBtn = xpath('//a[contains(text(), "Submit") or contains(@title, "Submit")]');
  if (!submitBtn) submitBtn = xpath('//input[@value="Submit" or @title="Submit"]');
  if (!submitBtn) submitBtn = xpath('//*[contains(text(), "Submit") and not(*)]');

  if (!submitBtn) return { success: false, error: "Submit button disappeared", data: null };
  
  submitBtn.scrollIntoView({ block: "center", behavior: "smooth" });
  submitBtn.click();
  
  // Wait for data table rows to appear
  for (let i = 0; i < 50; i++) {
    const dataRows = targetDoc.querySelectorAll('tr[rt="1"][rr]:not([rr="0"])');
    if (dataRows.length > 0) break;
    await wait(100);
  }
  
  // Parse table
  const headerRow = targetDoc.querySelector('tr[rt="2"]');
  if (!headerRow) return { success: false, error: "No table headers found", data: null };
  
  const headers = Array.from(headerRow.querySelectorAll("th"));
  const colMap = {};
  
  headers.forEach((th, idx) => {
    const key = th.innerText.trim().replace(/[^a-zA-Z0-9]/g, "").toLowerCase();
    if (["subject"].includes(key)) colMap.subject = idx;
    if (["noofpresent", "numberofpresent", "present"].includes(key)) colMap.present = idx;
    if (["noofabsent", "numberofabsent", "absent"].includes(key)) colMap.absent = idx;
    if (["totalpercentage", "percentage"].includes(key)) colMap.percentage = idx;
    if (["totalnoofdays", "totaldays"].includes(key)) colMap.totalDays = idx;
    if (["noofexcuses", "excuses"].includes(key)) colMap.excuses = idx;
    if (["facultyname", "faculty"].includes(key)) colMap.facultyName = idx;
  });
  
  const rows = targetDoc.querySelectorAll('tr[rt="1"]');
  const results = [];
  
  rows.forEach((row) => {
    const rank = row.getAttribute("rr");
    if (!rank || rank === "0") return;
    
    const cells = row.querySelectorAll("td");
    const getCell = (idx) => (idx === undefined || !cells[idx]) ? "" : cells[idx].innerText.trim();
    
    const subject = getCell(colMap.subject);
    if (subject) {
      results.push({
        subject: subject,
        present: getCell(colMap.present),
        totalDays: getCell(colMap.totalDays),
        absent: getCell(colMap.absent),
        percentage: getCell(colMap.percentage),
        facultyName: getCell(colMap.facultyName),
        excuses: getCell(colMap.excuses),
      });
    }
  });
  
  if (results.length === 0) {
    return { success: false, error: "No attendance records found in table", data: null };
  }
  
  return { success: true, error: null, data: results };
}
