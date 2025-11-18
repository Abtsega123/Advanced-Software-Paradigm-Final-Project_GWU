// Plagiarism Checker JavaScript

class PlagiarismChecker {
    constructor() {
        this.fileInput = document.getElementById('fileInput');
        this.uploadArea = document.getElementById('uploadArea');
        this.textInput = document.getElementById('textInput');
        this.checkButton = document.getElementById('checkPlagiarismBtn');
        this.clearButton = document.getElementById('clearBtn');
        this.progressSection = document.getElementById('progressSection');
        this.resultsSection = document.getElementById('resultsSection');
        this.errorSection = document.getElementById('errorSection');
        this.fileInfo = document.getElementById('fileInfo');
        this.excludeQuotesToggle = document.getElementById('excludeQuotesToggle');
        
        this.currentFileId = null;
        this.isProcessing = false;
        this.excludeQuotes = false;
        this.currentResults = null;
        this.plagiarismChart = null;
        
        this.initializeEventListeners();
        this.updateCharCount();
    }
    
    initializeEventListeners() {
        // File upload events
        this.uploadArea.addEventListener('click', () => this.fileInput.click());
        this.uploadArea.addEventListener('dragover', this.handleDragOver.bind(this));
        this.uploadArea.addEventListener('drop', this.handleDrop.bind(this));
        this.uploadArea.addEventListener('dragleave', this.handleDragLeave.bind(this));
        this.fileInput.addEventListener('change', this.handleFileSelect.bind(this));
        
        // Text input events
        this.textInput.addEventListener('input', this.handleTextInput.bind(this));
        
        // Button events
        this.checkButton.addEventListener('click', this.checkPlagiarism.bind(this));
        this.clearButton.addEventListener('click', this.clearAll.bind(this));
        
        // Toggle events
        this.excludeQuotesToggle.addEventListener('click', () => {
            this.excludeQuotes = !this.excludeQuotes;
            this.excludeQuotesToggle.classList.toggle('active');
        });
        
        // Dark mode toggle
        const darkModeToggle = document.getElementById('darkModeToggle');
        const darkModeIcon = document.getElementById('darkModeIcon');
        
        // Check saved preference
        if (localStorage.getItem('darkMode') === 'enabled') {
            document.body.classList.add('dark-mode');
            darkModeIcon.classList.replace('fa-moon', 'fa-sun');
        }
        
        darkModeToggle.addEventListener('click', () => {
            document.body.classList.toggle('dark-mode');
            
            if (document.body.classList.contains('dark-mode')) {
                darkModeIcon.classList.replace('fa-moon', 'fa-sun');
                localStorage.setItem('darkMode', 'enabled');
            } else {
                darkModeIcon.classList.replace('fa-sun', 'fa-moon');
                localStorage.setItem('darkMode', 'disabled');
            }
        });
        
        // Prevent default drag behaviors
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            this.uploadArea.addEventListener(eventName, (e) => {
                e.preventDefault();
                e.stopPropagation();
            });
        });
    }
    
    handleDragOver(e) {
        this.uploadArea.classList.add('dragover');
    }
    
    handleDragLeave(e) {
        this.uploadArea.classList.remove('dragover');
    }
    
    handleDrop(e) {
        this.uploadArea.classList.remove('dragover');
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            this.fileInput.files = files;
            this.handleFileSelect();
        }
    }
    
    handleFileSelect() {
        const file = this.fileInput.files[0];
        if (!file) return;
        
        // Clear text input when file is selected
        this.textInput.value = '';
        this.updateCharCount();
        
        this.uploadFile(file);
    }
    
    handleTextInput() {
        // Clear file selection when text is entered
        if (this.textInput.value.trim()) {
            this.fileInput.value = '';
            this.currentFileId = null;
            this.hideFileInfo();
        }
        
        this.updateCharCount();
        this.updateButtonState();
    }
    
    updateCharCount() {
        const text = this.textInput.value;
        document.getElementById('charCount').textContent = text.length;
        document.getElementById('wordCount').textContent = text.trim().split(/\s+/).filter(word => word).length;
    }
    
    updateButtonState() {
        const hasFile = this.currentFileId !== null;
        const hasText = this.textInput.value.trim().length >= 50;
        this.checkButton.disabled = this.isProcessing || (!hasFile && !hasText);
    }
    
    async uploadFile(file) {
        try {
            this.showProgress('Uploading file...');
            
            const formData = new FormData();
            formData.append('file', file);
            
            const response = await fetch('/api/upload', {
                method: 'POST',
                body: formData
            });
            
            const result = await response.json();
            
            if (response.ok && result.success) {
                this.currentFileId = result.fileId;
                this.showFileInfo(result);
                this.updateButtonState();
                this.hideProgress();
            } else {
                throw new Error(result.error || 'Upload failed');
            }
        } catch (error) {
            this.showError('File upload failed: ' + error.message);
            this.hideProgress();
        }
    }
    
    async checkPlagiarism() {
        if (this.isProcessing) return;
        
        this.isProcessing = true;
        this.updateButtonState();
        this.hideError();
        this.hideResults();
        
        try {
            let endpoint, data;
            
            if (this.currentFileId) {
                // Check file
                endpoint = '/api/check-plagiarism';
                data = { 
                    fileId: this.currentFileId,
                    excludeQuotes: this.excludeQuotes
                };
                this.showProgress('Analyzing document for plagiarism...');
            } else {
                // Check text
                endpoint = '/api/check-text';
                data = { 
                    text: this.textInput.value.trim(),
                    excludeQuotes: this.excludeQuotes
                };
                this.showProgress('Analyzing text for plagiarism...');
            }
            
            this.simulateProgress();
            
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });
            
            const result = await response.json();
            
            if (response.ok && result.success) {
                this.showResults(result.results);
            } else {
                throw new Error(result.error || 'Analysis failed');
            }
        } catch (error) {
            this.showError('Plagiarism check failed: ' + error.message);
        } finally {
            this.isProcessing = false;
            this.updateButtonState();
            this.hideProgress();
        }
    }
    
    simulateProgress() {
        const progressBar = document.getElementById('progressBar');
        const progressText = document.getElementById('progressText');
        const progressSection = this.progressSection.querySelector('.card-body');
        
        let progress = 0;
        let stage = 0;
        const stages = [
            'Preparing text for analysis...',
            'Creating optimized search chunks...',
            'Searching multiple engines in parallel...',
            'Fetching and analyzing content...',
            'Calculating similarity scores...',
            'Generating detailed report...'
        ];
        
        // Add percentage display
        if (!progressSection.querySelector('.progress-percentage')) {
            const percentDiv = document.createElement('div');
            percentDiv.className = 'progress-percentage';
            percentDiv.id = 'progressPercentage';
            progressSection.insertBefore(percentDiv, progressSection.querySelector('.progress'));
        }
        
        const interval = setInterval(() => {
            progress += Math.random() * 8 + 2;
            if (progress > 95) progress = 95;
            
            progressBar.style.width = progress + '%';
            document.getElementById('progressPercentage').textContent = `${Math.round(progress)}% Complete`;
            
            // Update stage
            const newStage = Math.floor(progress / 16);
            if (newStage !== stage && newStage < stages.length) {
                stage = newStage;
                progressText.textContent = stages[stage];
            }
        }, 400);
        
        // Clear interval when done
        setTimeout(() => {
            clearInterval(interval);
            progressBar.style.width = '100%';
            document.getElementById('progressPercentage').textContent = '100% Complete';
            progressText.textContent = 'Finalizing results...';
        }, 8000);
    }
    
    showFileInfo(fileData) {
        const fileDetails = document.getElementById('fileDetails');
        fileDetails.innerHTML = `
            <div class="row">
                <div class="col-md-6">
                    <strong>Filename:</strong> ${fileData.filename}<br>
                    <strong>Words:</strong> ${fileData.wordCount.toLocaleString()}
                </div>
                <div class="col-md-6">
                    <strong>Characters:</strong> ${fileData.characterCount.toLocaleString()}<br>
                    <small class="text-muted">Ready for analysis</small>
                </div>
            </div>
        `;
        this.fileInfo.style.display = 'block';
    }
    
    hideFileInfo() {
        this.fileInfo.style.display = 'none';
    }
    
    showProgress(message) {
        document.getElementById('progressText').textContent = message;
        document.getElementById('progressBar').style.width = '0%';
        this.progressSection.style.display = 'block';
        
        // Add warning about not refreshing
        const progressBody = this.progressSection.querySelector('.card-body');
        if (!progressBody.querySelector('.progress-warning')) {
            const warningDiv = document.createElement('div');
            warningDiv.className = 'progress-warning';
            warningDiv.innerHTML = `
                <i class="fas fa-exclamation-triangle"></i>
                <strong>Please wait:</strong> Analysis may take 1-3 minutes for longer documents. 
                Do not refresh or close this tab during processing.
            `;
            progressBody.appendChild(warningDiv);
        }
    }
    
    hideProgress() {
        this.progressSection.style.display = 'none';
    }
    
    showResults(results) {
        this.currentResults = results;
        const resultsBody = this.resultsSection.querySelector('.card-body');
        
        // Determine score class
        let scoreClass = 'score-low';
        if (results.plagiarism_percentage > 15) scoreClass = 'score-medium';
        if (results.plagiarism_percentage > 30) scoreClass = 'score-high';
        if (results.plagiarism_percentage > 50) scoreClass = 'score-critical';
        
        let html = `
            <div class="plagiarism-score-container">
                <div class="plagiarism-score ${scoreClass}">
                    ${results.plagiarism_percentage}%
                </div>
                <h6 class="mt-3">Plagiarism Detected</h6>
                <button class="btn btn-download mt-3" onclick="plagiarismChecker.downloadPDF()">
                    <i class="fas fa-file-pdf me-2"></i>Download PDF Report
                </button>
            </div>
            
            <div class="row results-stats-row">
                <div class="col-6 col-md-3">
                    <div class="stat-card stat-primary">
                        <span class="stat-value">${results.total_words.toLocaleString()}</span>
                        <span class="stat-label">Total Words</span>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card stat-${scoreClass === 'score-low' ? 'success' : scoreClass === 'score-critical' ? 'danger' : 'warning'}">
                        <span class="stat-value">${results.plagiarized_words.toLocaleString()}</span>
                        <span class="stat-label">Flagged Words</span>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card stat-warning">
                        <span class="stat-value">${results.sources_found}</span>
                        <span class="stat-label">Sources Found</span>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="stat-card stat-primary">
                        <span class="stat-value">${results.matches ? results.matches.length : 0}</span>
                        <span class="stat-label">Matches</span>
                    </div>
                </div>
            </div>
            
            <div class="chart-container">
                <canvas id="plagiarismChart"></canvas>
            </div>
        `;
        
        // Analysis summary
        html += `
            <div class="alert alert-info">
                <h6><i class="fas fa-info-circle me-2"></i>Analysis Summary</h6>
                <p class="mb-0">${results.analysis_summary}</p>
            </div>
        `;
        
        // Sources
        if (results.sources && results.sources.length > 0) {
            html += `<h6 class="mt-4 mb-3"><i class="fas fa-external-link-alt me-2"></i>Sources Found</h6>`;
            
            results.sources.forEach((source, index) => {
                html += `
                    <div class="source-card p-3">
                        <div class="d-flex justify-content-between align-items-start">
                            <div class="flex-grow-1">
                                <h6>
                                    <a href="${source.url}" target="_blank" class="source-title">
                                        ${source.title || 'Untitled Source'}
                                    </a>
                                </h6>
                                <small class="text-muted">${source.url}</small>
                                <div class="mt-2">
                                    <span class="badge bg-primary">
                                        ${source.match_count} match${source.match_count !== 1 ? 'es' : ''}
                                    </span>
                                    <span class="badge bg-warning ms-1">
                                        ${(source.avg_similarity * 100).toFixed(1)}% similarity
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });
        }
        
        // Individual matches
        if (results.matches && results.matches.length > 0) {
            html += `<h6 class="mt-4 mb-3"><i class="fas fa-list me-2"></i>Detailed Matches</h6>`;
            
            results.matches.slice(0, 10).forEach((match, index) => {
                html += `
                    <div class="match-card card p-3 mb-3">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <h6 class="mb-0">Match ${index + 1}</h6>
                            <span class="badge bg-warning similarity-badge">
                                ${(match.similarity * 100).toFixed(1)}% Similar
                            </span>
                        </div>
                        <div class="row">
                            <div class="col-md-6">
                                <strong>Original Text:</strong>
                                <div class="matched-text">${match.original_text}</div>
                            </div>
                            <div class="col-md-6">
                                <strong>Found in Source:</strong>
                                <div class="matched-text">${match.matched_text}</div>
                                <small class="text-muted mt-1">
                                    <a href="${match.url}" target="_blank">${match.title}</a>
                                </small>
                            </div>
                        </div>
                    </div>
                `;
            });
            
            if (results.matches.length > 10) {
                html += `<p class="text-muted">Showing top 10 matches. ${results.matches.length - 10} more matches found.</p>`;
            }
        }
        
        resultsBody.innerHTML = html;
        this.resultsSection.style.display = 'block';
        
        // Render chart
        this.renderChart(results);
        
        this.resultsSection.scrollIntoView({ behavior: 'smooth' });
    }
    
    renderChart(results) {
        const ctx = document.getElementById('plagiarismChart');
        if (!ctx) return;
        
        // Destroy previous chart if exists
        if (this.plagiarismChart) {
            this.plagiarismChart.destroy();
        }
        
        const originalPercentage = 100 - results.plagiarism_percentage;
        
        this.plagiarismChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Original Content', 'Plagiarized Content'],
                datasets: [{
                    data: [originalPercentage, results.plagiarism_percentage],
                    backgroundColor: [
                        'rgba(16, 185, 129, 0.8)',
                        'rgba(239, 68, 68, 0.8)'
                    ],
                    borderColor: [
                        'rgb(16, 185, 129)',
                        'rgb(239, 68, 68)'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 15,
                            font: {
                                size: 14,
                                weight: '600'
                            }
                        }
                    },
                    title: {
                        display: true,
                        text: 'Content Originality Analysis',
                        font: {
                            size: 18,
                            weight: '700'
                        },
                        padding: {
                            top: 10,
                            bottom: 20
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return context.label + ': ' + context.parsed.toFixed(1) + '%';
                            }
                        }
                    }
                }
            }
        });
    }
    
    downloadPDF() {
        if (!this.currentResults) return;
        
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();
        const results = this.currentResults;
        
        // Header
        doc.setFontSize(22);
        doc.setTextColor(37, 99, 235);
        doc.text('Plagiarism Analysis Report', 20, 20);
        
        doc.setFontSize(10);
        doc.setTextColor(100, 116, 139);
        doc.text(`Generated: ${new Date().toLocaleString()}`, 20, 28);
        
        // Summary Box
        doc.setFillColor(248, 250, 252);
        doc.rect(20, 35, 170, 35, 'F');
        
        doc.setFontSize(16);
        doc.setTextColor(15, 23, 42);
        doc.text('Plagiarism Score', 25, 45);
        
        doc.setFontSize(32);
        const scoreColor = results.plagiarism_percentage > 30 ? [239, 68, 68] : 
                          results.plagiarism_percentage > 15 ? [245, 158, 11] : [16, 185, 129];
        doc.setTextColor(...scoreColor);
        doc.text(`${results.plagiarism_percentage}%`, 25, 62);
        
        // Statistics
        doc.setFontSize(12);
        doc.setTextColor(15, 23, 42);
        doc.text('Analysis Summary', 20, 85);
        
        doc.setFontSize(10);
        doc.setTextColor(100, 116, 139);
        const stats = [
            `Total Words: ${results.total_words.toLocaleString()}`,
            `Flagged Words: ${results.plagiarized_words.toLocaleString()}`,
            `Sources Found: ${results.sources_found}`,
            `Matches Detected: ${results.matches ? results.matches.length : 0}`
        ];
        
        stats.forEach((stat, i) => {
            doc.text(stat, 25, 95 + (i * 7));
        });
        
        // Analysis Summary
        doc.setFontSize(11);
        doc.setTextColor(15, 23, 42);
        doc.text('Assessment:', 20, 125);
        doc.setFontSize(10);
        doc.setTextColor(71, 85, 105);
        const summary = doc.splitTextToSize(results.analysis_summary, 170);
        doc.text(summary, 20, 133);
        
        // Sources
        if (results.sources && results.sources.length > 0) {
            let yPos = 150;
            doc.setFontSize(12);
            doc.setTextColor(15, 23, 42);
            doc.text('Top Sources Found:', 20, yPos);
            
            doc.setFontSize(9);
            results.sources.slice(0, 5).forEach((source, i) => {
                yPos += 10;
                if (yPos > 270) {
                    doc.addPage();
                    yPos = 20;
                }
                
                doc.setTextColor(37, 99, 235);
                const title = doc.splitTextToSize(source.title || 'Untitled', 170);
                doc.text(title[0], 25, yPos);
                
                yPos += 5;
                doc.setTextColor(100, 116, 139);
                doc.text(`Similarity: ${(source.avg_similarity * 100).toFixed(1)}% | Matches: ${source.match_count}`, 25, yPos);
                
                yPos += 4;
                doc.setTextColor(148, 163, 184);
                const urlText = doc.splitTextToSize(source.url, 160);
                doc.text(urlText[0], 25, yPos);
                yPos += 5;
            });
        }
        
        // Footer
        const pageCount = doc.internal.getNumberOfPages();
        for (let i = 1; i <= pageCount; i++) {
            doc.setPage(i);
            doc.setFontSize(8);
            doc.setTextColor(148, 163, 184);
            doc.text(`Page ${i} of ${pageCount}`, 105, 290, { align: 'center' });
            doc.text('Generated by Advanced Plagiarism Checker v4.0', 105, 285, { align: 'center' });
        }
        
        // Save
        doc.save('plagiarism-report.pdf');
    }
    
    hideResults() {
        this.resultsSection.style.display = 'none';
    }
    
    showError(message) {
        document.getElementById('errorMessage').textContent = message;
        this.errorSection.style.display = 'block';
        this.errorSection.scrollIntoView({ behavior: 'smooth' });
    }
    
    hideError() {
        this.errorSection.style.display = 'none';
    }
    
    clearAll() {
        this.fileInput.value = '';
        this.textInput.value = '';
        this.currentFileId = null;
        this.updateCharCount();
        this.updateButtonState();
        this.hideFileInfo();
        this.hideResults();
        this.hideError();
        this.hideProgress();
    }
}

// Initialize the application when DOM is loaded
let plagiarismChecker;
document.addEventListener('DOMContentLoaded', () => {
    plagiarismChecker = new PlagiarismChecker();
});